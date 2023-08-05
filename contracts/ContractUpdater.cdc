pub contract ContractUpdater {

    /* --- Canonical Paths --- */
    pub let UpdaterStoragePath: StoragePath
    pub let DelegatedUpdaterPrivatePath: PrivatePath
    pub let UpdaterPublicPath: PublicPath
    pub let UpdaterContractAccountPrivatePath: PrivatePath
    pub let DelegateeStoragePath: StoragePath
    pub let DelegateePrivatePath: PrivatePath
    pub let DelegateePublicPath: PublicPath

    /* --- Events --- */
    pub event UpdaterCreated(updaterUUID: UInt64, blockUpdateBoundary: UInt64)
    pub event UpdaterUpdated(
        updaterUUID: UInt64,
        updaterAddress: Address?,
        blockUpdateBoundary: UInt64,
        updatedAddresses: [Address],
        updatedContracts: [String],
        failedAddresses: [Address],
        failedContracts: [String]
    )
    pub event UpdaterDelegationChanged(updaterUUID: UInt64, updaterAddress: Address?, delegated: Bool)

    /// Represents contract and its corresponding code
    ///
    pub struct ContractUpdate {
        pub let address: Address
        pub let name: String
        pub let code: [UInt8]

        init(address: Address, name: String, code: [UInt8]) {
            self.address = address
            self.name = name
            self.code = code
        }

        /// Serializes the address and name into a string
        pub fun toString(): String {
            return self.address.toString().concat(".").concat(self.name)
        }

        /// Returns code as a String
        pub fun stringifyCode(): String {
            return String.fromUTF8(self.code) ?? panic("Problem stringifying code!")
        }
    }

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
        pub fun getContractAccountAddresses(): [Address]
        pub fun getDeployment(): [ContractUpdate]
        pub fun hasBeenUpdated(): Bool
    }

    /// Resource that enables delayed contract updates to a wrapped account at or beyond a specified block height
    ///
    pub resource Updater : UpdaterPublic, DelegatedUpdater {
        /// Update to occur at or beyond this block height
        // TODO: Consider making this a contract-owned value as it's reflective of the spork height
        access(self) let blockUpdateBoundary: UInt64
        /// Update status for each contract
        access(self) var updated: Bool
        /// Capabilities for contract hosting accounts
        access(self) let accounts: {Address: Capability<&AuthAccount>}
        /// Order of updates to be performed
        /// NOTE: Dev should be careful to validate their dependency tree such that updates are performed from root 
        /// to leaf dependencies
        access(self) let deployment: [ContractUpdate]

        init(
            blockUpdateBoundary: UInt64,
            accounts: [Capability<&AuthAccount>],
            deployment: [ContractUpdate]
        ) {
            self.blockUpdateBoundary = blockUpdateBoundary
            self.updated = false
            self.accounts = {}
            // Validate given Capabilities
            for account in accounts {
                if !account.check() {
                    panic("Account capability is invalid for account: ".concat(account.address.toString()))
                }
                self.accounts.insert(key: account.borrow()!.address, account)
            }
            // Validate given deployment
            for contractUpdate in deployment {
                if !self.accounts.containsKey(contractUpdate.address) {
                    panic("Contract address not found in given accounts: ".concat(contractUpdate.address.toString()))
                }
            }
            self.deployment = deployment
        }

        /// Executes the update using Account.Contracts.update__experimental() for all contracts defined in deployment,
        /// returning true if either update was previously completed or all updates succeed, and false if any update
        /// fails
        ///
        pub fun update(): Bool {
            // Return early if we've already updated
            if self.updated {
                return true
            }
            
            let updatedAddresses: [Address] = []
            let failedAddresses: [Address] = []
            let updatedContracts: [String] = []
            let failedContracts: [String] = []

            // Update the contracts as specified in the deployment
            for contractUpdate in self.deployment {
                // Borrow the contract account
                if let account = self.accounts[contractUpdate.address]!.borrow() {
                    // Update the contract
                    // TODO: Swap out optional/Bool API tryUpdate() (or similar) and do stuff if update fails
                    // if account.contracts.tryUpdate(name: contractUpdate.name, code: contractUpdate.code) == false {
                    //     failedAddresses.append(account.address)
                    //     failedContracts.append(contractUpdate.toString())
                    //     continue
                    // } else {
                    //     if !updatedAddresses.contains(account.address) {
                    //         updatedAddresses.append(account.address)
                    //     }
                    //     if !updatedContracts.contains(contractUpdate.toString()) {
                    //         updatedContracts.append(contractUpdate.toString())
                    //     }
                    // }
                    account.contracts.update__experimental(name: contractUpdate.name, code: contractUpdate.code)
                    if !updatedAddresses.contains(account.address) {
                        updatedAddresses.append(account.address)
                    }
                    if !updatedContracts.contains(contractUpdate.toString()) {
                        updatedContracts.append(contractUpdate.toString())
                    }
                }
            }
            if failedContracts.length == 0 {
                self.updated = true
            }
            emit UpdaterUpdated(
                updaterUUID: self.uuid,
                updaterAddress: self.owner?.address,
                blockUpdateBoundary: self.blockUpdateBoundary,
                updatedAddresses: updatedAddresses,
                updatedContracts: updatedContracts,
                failedAddresses: failedAddresses,
                failedContracts: failedContracts
            )
            return self.updated
        }

        /* --- Public getters --- */

        pub fun getID(): UInt64 {
            return self.uuid
        }

        pub fun getBlockUpdateBoundary(): UInt64 {
            return self.blockUpdateBoundary
        }

        pub fun getContractAccountAddresses(): [Address] {
            return self.accounts.keys
        }

        pub fun getDeployment(): [ContractUpdate] {
            return self.deployment
        }

        pub fun hasBeenUpdated(): Bool {
            return self.updated
        }
    }

    /* --- Delegatee --- */
    //
    /// Public interface for Delegatee
    ///
    pub resource interface DelegateePublic {
        pub fun check(id: UInt64): Bool?
        pub fun delegate(updaterCap: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>)
        pub fun removeAsUpdater(updaterCap: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>)
    }

    /// Resource that executed delegated updates
    ///
    pub resource Delegatee : DelegateePublic{
        // TODO: Block Height - All DelegatedUpdaters must be updated at or beyond this block height
        // access(self) let blockUpdateBoundary: UInt64
        /// Track all delegated updaters
        access(self) let delegatedUpdaters: {UInt64: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>}

        init() {
            self.delegatedUpdaters = {}
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
            } else {
                // Insert if updater does not exist
                self.delegatedUpdaters.insert(key: updater.getID(), updaterCap)
            }
            emit UpdaterDelegationChanged(updaterUUID: updater.getID(), updaterAddress: updater.owner?.address, delegated: true)
        }

        /// Enables Updaters to remove their delegation
        ///
        pub fun removeAsUpdater(updaterCap: Capability<&Updater{DelegatedUpdater, UpdaterPublic}>) {
            pre {
                updaterCap.check(): "Invalid DelegatedUpdater Capability!"
                self.delegatedUpdaters.containsKey(updaterCap.borrow()!.getID()): "No Updater found for ID!"
            }
            let updater = updaterCap.borrow()!
            self.removeDelegatedUpdater(id: updater.getID())
        }

        /// Executes update on the specified Updater
        ///
        // TODO: Reconsider this signature - how can we ensure failed updates don't prevent others from updating?
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
                        self.removeDelegatedUpdater(id: id)
                    }
                }
            }
            return failed
        }

        /// Checks if the specified DelegatedUpdater Capability is valid
        ///
        pub fun check(id: UInt64): Bool? {
            return self.delegatedUpdaters[id]?.check() ?? nil
        }

        /// Enables admin removal of a DelegatedUpdater Capability
        pub fun removeDelegatedUpdater(id: UInt64) {
            if !self.delegatedUpdaters.containsKey(id) {
                return
            }
            let updaterCap = self.delegatedUpdaters.remove(key: id)!
            emit UpdaterDelegationChanged(updaterUUID: id, updaterAddress: updaterCap.borrow()?.owner?.address, delegated: false)
        }
    }

    /// Returns a new Updater resource
    ///
    pub fun createNewUpdater(
        blockUpdateBoundary: UInt64,
        accounts: [Capability<&AuthAccount>],
        deployment: [ContractUpdate]
    ): @Updater {
        let updater <- create Updater(blockUpdateBoundary: blockUpdateBoundary, accounts: accounts, deployment: deployment)
        emit UpdaterCreated(updaterUUID: updater.uuid, blockUpdateBoundary: blockUpdateBoundary)
        return <- updater
    }

    init() {
        self.UpdaterStoragePath = StoragePath(identifier: "ContractUpdater_".concat(self.account.address.toString()))!
        self.DelegatedUpdaterPrivatePath = PrivatePath(identifier: "ContractUpdaterDelegated_".concat(self.account.address.toString()))!
        self.UpdaterPublicPath = PublicPath(identifier: "ContractUpdaterPublic_".concat(self.account.address.toString()))!
        self.UpdaterContractAccountPrivatePath = PrivatePath(identifier: "UpdaterContractAccount_".concat(self.account.address.toString()))!
        self.DelegateeStoragePath = StoragePath(identifier: "ContractUpdaterDelegatee_".concat(self.account.address.toString()))!
        self.DelegateePrivatePath = PrivatePath(identifier: "ContractUpdaterDelegatee_".concat(self.account.address.toString()))!
        self.DelegateePublicPath = PublicPath(identifier: "ContractUpdaterDelegateePublic_".concat(self.account.address.toString()))!

        self.account.save(<-create Delegatee(), to: self.DelegateeStoragePath)
        self.account.link<&{DelegateePublic}>(self.DelegateePublicPath, target: self.DelegateePrivatePath)
    }
}