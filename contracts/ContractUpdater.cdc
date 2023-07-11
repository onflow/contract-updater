pub contract ContractUpdater {

    pub let UpdaterStoragePath: StoragePath
    pub let DelegatedUpdaterPrivatePath: PrivatePath
    pub let UpdaterPublicPath: PublicPath
    pub let UpdaterContractAccountPrivatePath: PrivatePath
    pub let DelegateeStoragePath: StoragePath
    pub let DelegateePrivatePath: PrivatePath
    pub let DelegateePublicPath: PublicPath

    pub event UpdaterUpdated(updaterUUID: UInt64, blockUpdateBoundary: UInt64, contractAccountAddress: Address, contractName: String, updated: Bool)
    pub event UpdaterDelegationChanged(updaterUUID: UInt64, contractAccountAddress: Address, contractName: String?, delegated: Bool)

    /* --- Updater --- */
    //
    /// Private Capability enabling delegated updates
    ///
    pub resource interface DelegatedUpdater {
        pub fun update(): Bool
    }

    /// Public interface enabling queries about the Updater
    ///
    pub resource interface UpdaterPublic {
        pub fun getID(): UInt64
        pub fun getBlockUpdateBoundary(): UInt64
        pub fun getContractAccountAddress(): Address
        pub fun getContractName(): String
        pub fun getContractCode(): String
        pub fun getContractCodeAsBytes(): [UInt8]
        pub fun hasBeenUpdated(): Bool
    }

    /// Resource that enables delayed contract updates to a wrapped account at or beyond a specified block height
    ///
    // TODO: Consider mapping of contractName: code to enable multi-contract updates within updater - simplifies delegatee resource on per account basis instead of multi-mapping
    pub resource Updater : UpdaterPublic, DelegatedUpdater {
        /// Update to occur at or beyond this block height
        access(self) let blockUpdateBoundary: UInt64
        /// Capability to the account where the contract will be updated
        access(self) let contractAccount: Capability<&AuthAccount>
        /// Name of the contract to be updated
        access(self) let contractName: String
        /// Code to update the contract to
        access(self) var code: [UInt8]
        /// Has the update occurred?
        access(self) var updated: Bool
        
        init(blockUpdateBoundary: UInt64, contractAccount: Capability<&AuthAccount>, contractName: String, code: [UInt8]) {
            pre {
                contractAccount.check(): "Invalid AuthAccount Capability!"
            }
            self.blockUpdateBoundary = blockUpdateBoundary
            self.contractAccount = contractAccount
            self.contractName = contractName
            self.code = code
            self.updated = false
        }

        /// Executes the update using Account.Contracts.update__experimental(), returning true if the update completed
        ///
        pub fun update(): Bool {
            if self.updated || self.blockUpdateBoundary > getCurrentBlock().height {
                return false
            }
            self.borrowAccount().contracts.update__experimental(name: self.getContractName(), code: self.getContractCodeAsBytes())
            self.updated = true
            emit UpdaterUpdated(
                updaterUUID: self.uuid,
                blockUpdateBoundary: self.blockUpdateBoundary,
                contractAccountAddress: self.contractAccount.address,
                contractName: self.contractName,
                updated: self.updated
            )
            return true
        }

        /* --- Public getters --- */

        pub fun getID(): UInt64 {
            return self.uuid
        }

        pub fun getBlockUpdateBoundary(): UInt64 {
            return self.blockUpdateBoundary
        }

        pub fun getContractAccountAddress(): Address {
            return self.contractAccount.address
        }

        pub fun getContractName(): String {
            return self.contractName
        }

        pub fun getContractCode(): String {
            return String.fromUTF8(self.code) ?? panic("Problem stringifying code!")
        }

        pub fun getContractCodeAsBytes(): [UInt8] {
            return self.code
        }

        pub fun hasBeenUpdated(): Bool {
            return self.updated
        }

        /* --- Owner setter --- */

        pub fun setContractCode(code: [UInt8]) {
            self.code = code
        }

        /* --- Internal helper --- */

        access(self) fun borrowAccount(): &AuthAccount {
            return self.contractAccount.borrow() ?? panic("Could not borrow contract account from stored Capability!")
        }
    }

    /* --- Delegatee --- */
    //
    /// Public interface for Delegatee
    ///
    pub resource interface DelegateePublic {
        pub fun delegate(updater: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>)
        pub fun removeAsUpdater(updaterCap: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>)
    }

    /// Resource that executed delegated updates
    ///
    pub resource Delegatee {
        /// Track all delegated updaters
        access(self) let delegatedUpdaters: {UInt64: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>}
        /// Index updater IDs on the Address they update to
        access(self) let addressToIDs: {Address: [UInt64]}

        init() {
            self.delegatedUpdaters = {}
            self.addressToIDs = {}
        }

        /// Allows for the delegation of updates to a contract
        ///
        pub fun delegate(updaterCap: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>) {
            pre {
                updaterCap.check(): "Invalid DelegatedUpdater Capability!"
            }
            let updater = updaterCap.borrow()!
            if self.delegatedUpdaters.containsKey(updater.getID()) {
                // Upsert if updater already exists
                self.delegatedUpdaters[updater.getID()] = updaterCap
            } else if self.addressToIDs.containsKey(updater.getContractAccountAddress()) {
                // New Updater for known Address - append to existing array
                self.addressToIDs[updater.getContractAccountAddress()]!.append(updater.getID())
                self.delegatedUpdaters.insert(key: updater.getID(), updaterCap)
            } else {
                // New Updater entirely, insert into both maps
                self.addressToIDs.insert(key: updater.getContractAccountAddress(), [updater.getID()])
                self.delegatedUpdaters.insert(key: updater.getID(), updaterCap)
            }
            emit UpdaterDelegationChanged(updaterUUID: updater.getID(), contractAccountAddress: updater.getContractAccountAddress(), contractName: updater.getContractName(), delegated: true)
        }

        /// Enables Updaters to remove their delegation
        ///
        pub fun removeAsUpdater(updaterCap: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>) {
            pre {
                updaterCap.check(): "Invalid DelegatedUpdater Capability!"
                self.delegatedUpdaters.containsKey(updaterCap.borrow()!.getID()): "No Updater found for ID!"
            }
            let updater = updaterCap.borrow()!
            self.removeDelegatedUpdater(address: updater.getContractAccountAddress(), id: updater.getID())
        }

        /// Executes update on the specified Updater
        ///
        pub fun update(updaters: {Address: [UInt64]}): {Address: [UInt64]} {
            let failed: {Address: [UInt64]} = {}

            for address in updaters.keys {
                // If nothing found for address, skip
                if updaters[address] == nil {
                    failed[address] = []
                    continue
                }
                let ids = updaters[address]!
                for id in ids {
                    let updaterCap = self.delegatedUpdaters[id]!
                    if !updaterCap.check() {
                        failed[address]!.append(id)
                        continue
                    }
                    let success = updaterCap.borrow()!.update()
                    if !success && !failed.containsKey(address) {
                        failed.insert(key: address, [id])
                    } else if !success && failed.containsKey(address) {
                        failed[address]!.append(id)
                    } else {
                        // Updater updated, can now be removed
                        self.removeDelegatedUpdater(address: address, id: id)
                    }
                }
            }
            return failed
        }

        /// Checks if the specified DelegatedUpdater Capability is valid
        ///
        pub fun check(id: UInt64): Bool {
            pre {
                self.delegatedUpdaters.containsKey(id): "No Updater found for ID!"
            }
            return self.delegatedUpdaters[id]!.check()
        }

        /// Enables admin removal of a DelegatedUpdater Capability
        pub fun removeDelegatedUpdater(address: Address, id: UInt64) {
            if !self.addressToIDs.containsKey(address) || !self.addressToIDs[address]!.contains(id) {
                return
            }

            let ids = self.addressToIDs[address]!
            if ids.length == 1 {
                self.addressToIDs.remove(key: address)
            } else {
                self.addressToIDs[address]!.remove(at: ids.firstIndex(of: id)!)
            }

            var name: String? = nil
            if let cap = self.delegatedUpdaters.remove(key: id) {
                name = cap.borrow()?.getContractName()
            }
            
            emit UpdaterDelegationChanged(updaterUUID: id, contractAccountAddress: address, contractName: name, delegated: false)
        }
    }

    /// Returns a new Updater resource
    ///
    pub fun createNewUpdater(blockUpdateBoundary: UInt64, contractAccount: Capability<&AuthAccount>, contractName: String, code: [UInt8]): @Updater {
        let updater <- create Updater(blockUpdateBoundary: blockUpdateBoundary, contractAccount: contractAccount, contractName: contractName, code: code)
        emit UpdaterUpdated(
            updaterUUID: updater.uuid,
            blockUpdateBoundary: blockUpdateBoundary,
            contractAccountAddress: contractAccount.address,
            contractName: contractName,
            updated: false
        )
        return <- updater
    }

    init() {
        self.UpdaterStoragePath = /storage/ContractUpdater
        self.DelegatedUpdaterPrivatePath = /private/ContractUpdaterDelegated
        self.UpdaterPublicPath = /public/ContractUpdaterPublic
        self.UpdaterContractAccountPrivatePath = /private/UpdaterContractAccount
        self.DelegateeStoragePath = /storage/ContractUpdaterDelegatee
        self.DelegateePrivatePath = /private/ContractUpdaterDelegatee
        self.DelegateePublicPath = /public/ContractUpdaterDelegateePublic

        self.account.save(<-create Delegatee(), to: self.DelegateeStoragePath)
        self.account.link<&{DelegateePublic}>(self.DelegateePublicPath, target: self.DelegateePrivatePath)
    }
}