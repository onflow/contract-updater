/// This contract defines resources which enable storage of contract code for the purposes of updating at or beyond 
/// some blockheight boundary either by the containing resource's owner or by some delegated party.
///
/// The two primary resources involved in this are the @Updater and @Delegatee resources. As their names suggest, the
/// @Updater contains Capabilities for all deployment accounts as well as the corresponding contract code + names in
/// the order of their update deployment as well as a blockheight at or beyond which the update can be performed. The
/// @Delegatee resource can receive Capabilities to the @Updater resource and can perform the update on behalf of the
/// @Updater resource's owner.
///
/// At the time of this writing, failed updates are not handled gracefully and will result in the halted iteration, but
/// recent conversations point to the possibility of amending the Account.Contract API to allow for a graceful
/// recovery from failed updates. If this method is not added, we'll want to reconsider the approach in favor of a 
/// single update() call per transaction.
/// See the following issue for more info: https://github.com/onflow/cadence/issues/2700
///
// TODO: Consider how to handle large contracts that exceed the transaction limit
//     - It's common to chunk contract code and pass over numerous transactions - think about how could support a similar workflow
//       when configuring an Updater resource
// TODO: We can't rely on dependencies updating in the same transaction, we'll need to allow for blocking update deployments
access(all) contract ContractUpdater {

    /* --- Contract Values --- */
    //
    /// Prefix for published Account Capability
    access(all) let inboxAccountCapabilityNamePrefix: String

    /* --- Canonical Paths --- */
    //
    access(all) let UpdaterStoragePath: StoragePath
    access(all) let DelegatedUpdaterPrivatePath: PrivatePath
    access(all) let UpdaterPublicPath: PublicPath
    access(all) let UpdaterContractAccountPrivatePath: PrivatePath
    access(all) let DelegateeStoragePath: StoragePath
    access(all) let DelegateePrivatePath: PrivatePath
    access(all) let DelegateePublicPath: PublicPath


    /* --- Events --- */
    //
    access(all) event UpdaterCreated(updaterUUID: UInt64, blockUpdateBoundary: UInt64)
    access(all) event UpdaterUpdated(
        updaterUUID: UInt64,
        updaterAddress: Address?,
        blockUpdateBoundary: UInt64,
        updatedAddresses: [Address],
        updatedContracts: [String],
        failedAddresses: [Address],
        failedContracts: [String],
        updateComplete: Bool
    )
    access(all) event UpdaterDelegationChanged(updaterUUID: UInt64, updaterAddress: Address?, delegated: Bool)

    /// Represents contract and its corresponding code
    ///
    access(all) struct ContractUpdate {
        access(all) let address: Address
        access(all) let name: String
        access(all) let code: [UInt8]

        init(address: Address, name: String, code: [UInt8]) {
            self.address = address
            self.name = name
            self.code = code
        }

        /// Serializes the address and name into a string
        access(all) view fun toString(): String {
            return self.address.toString().concat(".").concat(self.name)
        }

        /// Returns code as a String
        access(all) view fun stringifyCode(): String {
            return String.fromUTF8(self.code) ?? panic("Problem stringifying code!")
        }
    }

    /* --- Updater --- */
    //
    /// Public interface enabling queries about the Updater
    ///
    access(all) resource interface UpdaterPublic {
        access(all) view fun getID(): UInt64
        access(all) view fun getBlockUpdateBoundary(): UInt64
        access(all) view fun getContractAccountAddresses(): [Address]
        access(all) view fun getDeployments(): [[ContractUpdate]]
        access(all) view fun getCurrentDeploymentStage(): Int
        access(all) view fun getFailedDeployments(): {Int: [String]}
        access(all) view fun hasBeenUpdated(): Bool
    }

    /// Resource that enables delayed contract updates to a wrapped account at or beyond a specified block height
    ///
    access(all) resource Updater : UpdaterPublic {
        /// Update to occur at or beyond this block height
        // TODO: Consider making this a contract-owned value as it's reflective of the spork height
        access(self) let blockUpdateBoundary: UInt64
        /// Update status for each contract
        access(self) var updateComplete: Bool
        /// Capabilities for contract hosting accounts
        access(self) let accounts: {Address: Capability<auth(Contracts) &Account>}
        /// Updates ordered by their deployment sequence and staged by their dependency depth
        /// NOTE: Dev should be careful to validate their dependency tree such that updates are performed from root 
        /// to leaf dependencies
        access(self) let deployments: [[ContractUpdate]]
        /// Current deployment stage
        access(self) var currentDeploymentStage: Int
        /// Contracts whose update failed keyed on their deployment stage
        access(self) let failedDeployments: {Int: [String]}

        init(
            blockUpdateBoundary: UInt64,
            accounts: [Capability<auth(Contracts)&Account>],
            deployments: [[ContractUpdate]]
        ) {
            self.blockUpdateBoundary = blockUpdateBoundary
            self.updateComplete = false
            self.accounts = {}
            // Validate given Capabilities
            for account in accounts {
                if !account.check() {
                    panic("Account capability is invalid for account: ".concat(account.address.toString()))
                }
                self.accounts.insert(key: account.borrow()!.address, account)
            }
            // Validate given deployment has corresponding account Capabilities
            for stage in deployments {
                for contractUpdate in stage {
                    if !self.accounts.containsKey(contractUpdate.address) {
                        panic("Contract address not found in given accounts: ".concat(contractUpdate.address.toString()))
                    }
                }
            }
            self.deployments = deployments
            self.currentDeploymentStage = 0
            self.failedDeployments = {}
        }

        /// Executes the next update stabe using Account.Contracts.update__experimental() for all contracts defined in
        /// deployment, returning true if all stages have been attempted and false if stages remain
        ///
        access(all) fun update(): Bool {
            // Return early if we've already updated
            if self.updateComplete {
                return true
            }
            
            let updatedAddresses: [Address] = []
            let failedAddresses: [Address] = []
            let updatedContracts: [String] = []
            let failedContracts: [String] = []

            // Update the contracts as specified in the deployment
            for contractUpdate in self.deployments[self.currentDeploymentStage] {
                // Borrow the contract account
                if let account = self.accounts[contractUpdate.address]!.borrow() {
                    // Update the contract
                    // TODO: Swap out optional/Bool API tryUpdate() (or similar) and do stuff if update fails
                    //      See: https://github.com/onflow/cadence/issues/2700
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
                    account.contracts.update(name: contractUpdate.name, code: contractUpdate.code)
                    if !updatedAddresses.contains(account.address) {
                        updatedAddresses.append(account.address)
                    }
                    if !updatedContracts.contains(contractUpdate.toString()) {
                        updatedContracts.append(contractUpdate.toString())
                    }
                }
            }
            
            if failedContracts.length > 0 {
                self.failedDeployments.insert(key: self.currentDeploymentStage, failedContracts)
            }
            
            self.currentDeploymentStage = self.currentDeploymentStage + 1
            self.updateComplete = self.currentDeploymentStage == self.deployments.length
            
            emit UpdaterUpdated(
                updaterUUID: self.uuid,
                updaterAddress: self.owner?.address,
                blockUpdateBoundary: self.blockUpdateBoundary,
                updatedAddresses: updatedAddresses,
                updatedContracts: updatedContracts,
                failedAddresses: failedAddresses,
                failedContracts: failedContracts,
                updateComplete: self.updateComplete
            )
            return self.updateComplete
        }

        /* --- Public getters --- */

        access(all) view fun getID(): UInt64 {
            return self.uuid
        }

        access(all) view fun getBlockUpdateBoundary(): UInt64 {
            return self.blockUpdateBoundary
        }

        access(all) view fun getContractAccountAddresses(): [Address] {
            return self.accounts.keys
        }

        access(all) view fun getDeployments(): [[ContractUpdate]] {
            return self.deployments
        }

        access(all) view fun getCurrentDeploymentStage(): Int {
            return self.currentDeploymentStage
        }

        access(all) view fun getFailedDeployments(): {Int: [String]} {
            return self.failedDeployments
        }

        access(all) view fun hasBeenUpdated(): Bool {
            return self.updateComplete
        }
    }

    /* --- Delegatee --- */
    //
    /// Public interface for Delegatee
    ///
    access(all) resource interface DelegateePublic {
        access(all) view fun check(id: UInt64): Bool?
        access(all) view fun getUpdaterIDs(): [UInt64]
        access(all) fun delegate(updaterCap: Capability<&Updater>)
        access(all) fun removeAsUpdater(updaterCap: Capability<&Updater>)
    }

    /// Resource that executed delegated updates
    ///
    access(all) resource Delegatee : DelegateePublic {
        // TODO: Block Height - All DelegatedUpdaters must be updated at or beyond this block height
        // access(self) let blockUpdateBoundary: UInt64
        /// Track all delegated updaters
        // TODO: If we support staged updates, we'll want visibility into the number of stages and progress through all
        //      maybe removing after stages have been complete or failed
        access(self) let delegatedUpdaters: {UInt64: Capability<&Updater>}

        init() {
            self.delegatedUpdaters = {}
        }

        /// Checks if the specified DelegatedUpdater Capability is contained and valid
        ///
        access(all) view fun check(id: UInt64): Bool? {
            return self.delegatedUpdaters[id]?.check() ?? nil
        }

        /// Returns the IDs of the delegated updaters 
        ///
        access(all) view fun getUpdaterIDs(): [UInt64] {
            return self.delegatedUpdaters.keys
        }

        /// Allows for the delegation of updates to a contract
        ///
        access(all) fun delegate(updaterCap: Capability<&Updater>) {
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
        access(all) fun removeAsUpdater(updaterCap: Capability<&Updater>) {
            pre {
                updaterCap.check(): "Invalid DelegatedUpdater Capability!"
                self.delegatedUpdaters.containsKey(updaterCap.borrow()!.getID()): "No Updater found for ID!"
            }
            let updater = updaterCap.borrow()!
            self.removeDelegatedUpdater(id: updater.getID())
        }

        /// Executes update on the specified Updater
        ///
        // TODO: Consider removing Capabilities once we get signal that the Updater has been completed
        access(all) fun update(updaterIDs: [UInt64]): [UInt64] {
            let failed: [UInt64] = []

            for id in updaterIDs {
                if self.delegatedUpdaters[id] == nil {
                    failed.append(id)
                    continue
                }
                let updaterCap = self.delegatedUpdaters[id]!
                if !updaterCap.check() {
                    failed.append(id)
                    continue
                }
                let success = updaterCap.borrow()!.update()
                if !success {
                    failed.append(id)
                }
            }
            return failed
        }

        /// Enables admin removal of a DelegatedUpdater Capability
        access(all) fun removeDelegatedUpdater(id: UInt64) {
            if !self.delegatedUpdaters.containsKey(id) {
                return
            }
            let updaterCap = self.delegatedUpdaters.remove(key: id)!
            emit UpdaterDelegationChanged(updaterUUID: id, updaterAddress: updaterCap.borrow()?.owner?.address, delegated: false)
        }
    }

    /// Returns the Address of the Delegatee associated with this contract
    ///
    access(all) view fun getContractDelegateeAddress(): Address {
        return self.account.address
    }

    /// Helper method that returns the ordered array reflecting sequenced and staged deployments, with each contract
    /// update represented by a ContractUpdate struct.
    ///
    /// NOTE: deploymentConfig is ordered, and the order is used to determine both the order of the contracts in each
    /// deployment and the order of the deployments themselves. Each entry in the inner array must be exactly one
    /// key-value pair, where the key is the address of the associated contract name and code.
    ///
    access(all) fun getDeploymentFromConfig(_ deploymentConfig: [[{Address: {String: String}}]]): [[ContractUpdate]] {
        let deployments: [[ContractUpdate]] = []

        for deploymentStage in deploymentConfig {

            let contractUpdates: [ContractUpdate] = []
            for contractConfig in deploymentStage {

                assert(contractConfig.length == 1, message: "Invalid contract config")
                let address = contractConfig.keys[0]
                assert(contractConfig[address]!.length == 1, message: "Invalid contract config")

                let nameAndCode = contractConfig[address]!
                contractUpdates.append(
                    ContractUpdater.ContractUpdate(
                        address: address,
                        name: nameAndCode.keys[0],
                        code: nameAndCode.values[0].decodeHex()
                    )
                )
            }

            deployments.append(
                contractUpdates
            )
        }

        return deployments
    }

    /// Returns a new Updater resource
    ///
    access(all) fun createNewUpdater(
        blockUpdateBoundary: UInt64,
        accounts: [Capability<auth(Contracts)&Account>],
        deployments: [[ContractUpdate]]
    ): @Updater {
        let updater <- create Updater(blockUpdateBoundary: blockUpdateBoundary, accounts: accounts, deployments: deployments)
        emit UpdaterCreated(updaterUUID: updater.uuid, blockUpdateBoundary: blockUpdateBoundary)
        return <- updater
    }

    /// Creates a new Delegatee resource enabling caller to self-host their Delegatee
    ///
    access(all) fun createNewDelegatee(): @Delegatee {
        return <- create Delegatee()
    }

    init() {
        self.inboxAccountCapabilityNamePrefix = "ContractUpdaterAccountCapability_"

        self.UpdaterStoragePath = StoragePath(identifier: "ContractUpdater_".concat(self.account.address.toString()))!
        self.DelegatedUpdaterPrivatePath = PrivatePath(identifier: "ContractUpdaterDelegated_".concat(self.account.address.toString()))!
        self.UpdaterPublicPath = PublicPath(identifier: "ContractUpdaterPublic_".concat(self.account.address.toString()))!
        self.UpdaterContractAccountPrivatePath = PrivatePath(identifier: "UpdaterContractAccount_".concat(self.account.address.toString()))!
        self.DelegateeStoragePath = StoragePath(identifier: "ContractUpdaterDelegatee_".concat(self.account.address.toString()))!
        self.DelegateePrivatePath = PrivatePath(identifier: "ContractUpdaterDelegatee_".concat(self.account.address.toString()))!
        self.DelegateePublicPath = PublicPath(identifier: "ContractUpdaterDelegateePublic_".concat(self.account.address.toString()))!

        self.account.storage.save(<-create Delegatee(), to: self.DelegateeStoragePath)
        let delegateePublicCap = self.account.capabilities.storage.issue<&{DelegateePublic}>(self.DelegateeStoragePath)
        self.account.capabilities.publish(delegateePublicCap, at: self.DelegateePublicPath)
    }
}