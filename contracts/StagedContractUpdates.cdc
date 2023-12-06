/// This contract defines resources which enable storage of contract code for the purposes of updating at or beyond
/// some blockheight boundary either by the containing resource's owner or by some delegated party.
///
/// The two primary resources involved in this are the @Updater and @Delegatee resources. As their names suggest, the
/// @Updater contains Capabilities for all deployment accounts (wrapped in @Host resources) as well as the
/// corresponding contract code + names in the order of their update deployment as well as a blockheight at or beyond
/// which the update can be performed. The @Delegatee resource can receive Capabilities to the @Updater resource and
/// can perform the update on behalf of the @Updater resource's owner.
///
/// At the time of this writing, failed updates are not handled gracefully and will result in the halted iteration, but
/// recent conversations point to the possibility of amending the AuthAccount.Contract API to allow for a graceful
/// recovery from failed updates. If this method is not added, we'll want to reconsider the approach in favor of a
/// single update() call per transaction.
/// See the following issue for more info: https://github.com/onflow/cadence/issues/2700
///
// TODO: Consider how to handle large contracts that exceed the transaction limit
//     - It's common to chunk contract code and pass over numerous transactions - think about how could support a similar workflow
//       when configuring an Updater resource
access(all) contract StagedContractUpdates {

    access(all) let inboxHostCapabilityNamePrefix: String

    /* --- Canonical Paths --- */
    //
    access(all) let HostStoragePath: StoragePath
    access(all) let UpdaterStoragePath: StoragePath
    // access(all) let DelegatedUpdaterPrivatePath: PrivatePath
    access(all) let UpdaterPublicPath: PublicPath
    // access(all) let UpdaterContractAccountPrivatePath: PrivatePath
    access(all) let DelegateeStoragePath: StoragePath
    // access(all) let DelegateePrivatePath: PrivatePath
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
        access(all) let code: String

        init(address: Address, name: String, code: String) {
            self.address = address
            self.name = name
            self.code = code
        }

        /// Serializes the address and name into a string
        access(all) fun toString(): String {
            return self.address.toString().concat(".").concat(self.name)
        }

        /// Returns code as a String
        access(all) fun codeAsCadence(): String {
            return String.fromUTF8(self.code.decodeHex()) ?? panic("Problem stringifying code!")
        }
    }

    /* --- Host --- */
    //
    /// Encapsulates an AuthAccount, exposing only the ability to update contracts on the underlying account
    ///
    access(all) resource Host {
        access(self) let accountCapability: Capability<&AuthAccount>

        init(accountCapability: Capability<&AuthAccount>) {
            self.accountCapability = accountCapability
        }

        /// Updates the contract with the specified name and code
        ///
        access(all) fun update(name: String, code: [UInt8]): Bool {
            if let account = self.accountCapability.borrow() {
                // TODO: Replace update__experimental with tryUpdate() once it's available
                // let deploymentResult = account.contracts.tryUpdate(name: name, code: code)
                // return deploymentResult.success
                account.contracts.update__experimental(name: name, code: code)
                return true
            }
            return false
        }

        /// Checks the wrapped AuthAccount Capability
        ///
        access(all) fun checkAccountCapability(): Bool {
            return self.accountCapability.check()
        }

        /// Returns the Address of the underlying account
        ///
        access(all) fun getHostAddress(): Address? {
            return self.accountCapability.borrow()?.address
        }
    }

    /* --- Updater --- */
    //
    /// Public interface enabling queries about the Updater
    ///
    access(all) resource interface UpdaterPublic {
        access(all) fun getID(): UInt64
        access(all) fun getBlockUpdateBoundary(): UInt64
        access(all) fun getContractAccountAddresses(): [Address]
        access(all) fun getDeployments(): [[ContractUpdate]]
        access(all) fun getCurrentDeploymentStage(): Int
        access(all) fun getFailedDeployments(): {Int: [String]}
        access(all) fun hasBeenUpdated(): Bool
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
        access(self) let hosts: {Address: Capability<&Host>}
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
            hosts: [Capability<&Host>],
            deployments: [[ContractUpdate]]
        ) {
            pre {
                hosts.length > 0 && deployments.length > 0: "Must provide at least one host and contract update!"
            }
            self.blockUpdateBoundary = blockUpdateBoundary
            self.updateComplete = false
            self.hosts = {}
            // Validate given Capabilities
            for host in hosts {
                if !host.check() || !host.borrow()!.checkAccountCapability() {
                    panic("Host capability is invalid for account: ".concat(host.address.toString()))
                }
                self.hosts.insert(key: host.borrow()!.getHostAddress()!, host)
            }
            // Validate given deployment has corresponding account Capabilities
            for stage in deployments {
                for contractUpdate in stage {
                    if !self.hosts.containsKey(contractUpdate.address) {
                        panic("Contract address not found in given accounts: ".concat(contractUpdate.address.toString()))
                    }
                }
            }
            self.deployments = deployments
            self.currentDeploymentStage = 0
            self.failedDeployments = {}
        }

        /// Executes the next update stage for all contracts defined in deployment, returning true if all stages have
        /// been attempted and false if stages remain
        ///
        access(all) fun update(): Bool {
            // Return early if we've already updated
            if self.updateComplete {
                return true
            } else if getCurrentBlock().height < self.blockUpdateBoundary {
                // TODO: Consider returning nil here - indicates an update isn't even attempted.
                //      Delegatee could then pop on nil since this Updater won't update at the attempted height anyway
                return false
            }

            let updatedAddresses: [Address] = []
            let failedAddresses: [Address] = []
            let updatedContracts: [String] = []
            let failedContracts: [String] = []

            // Update the contracts as specified in the deployment
            for contractUpdate in self.deployments[self.currentDeploymentStage] {
                if let host = self.hosts[contractUpdate.address]!.borrow() {
                    if host.update(name: contractUpdate.name, code: contractUpdate.code.decodeHex()) == false {
                        failedAddresses.append(contractUpdate.address)
                        failedContracts.append(contractUpdate.toString())
                        continue
                    } else {
                        if !updatedAddresses.contains(contractUpdate.address) {
                            updatedAddresses.append(contractUpdate.address)
                        }
                        if !updatedContracts.contains(contractUpdate.toString()) {
                            updatedContracts.append(contractUpdate.toString())
                        }
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

        access(all) fun getID(): UInt64 {
            return self.uuid
        }

        access(all) fun getBlockUpdateBoundary(): UInt64 {
            return self.blockUpdateBoundary
        }

        access(all) fun getContractAccountAddresses(): [Address] {
            return self.hosts.keys
        }

        access(all) fun getDeployments(): [[ContractUpdate]] {
            return self.deployments
        }

        access(all) fun getCurrentDeploymentStage(): Int {
            return self.currentDeploymentStage
        }

        access(all) fun getFailedDeployments(): {Int: [String]} {
            return self.failedDeployments
        }

        access(all) fun hasBeenUpdated(): Bool {
            return self.updateComplete
        }
    }

    /* --- Delegatee --- */
    //
    /// Public interface for Delegatee
    ///
    access(all) resource interface DelegateePublic {
        access(all) fun check(id: UInt64): Bool?
        access(all) fun getUpdaterIDs(): [UInt64]
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
        access(all) fun check(id: UInt64): Bool? {
            return self.delegatedUpdaters[id]?.check() ?? nil
        }

        /// Returns the IDs of the delegated updaters
        ///
        access(all) fun getUpdaterIDs(): [UInt64] {
            return self.delegatedUpdaters.keys
        }

        /// Allows for the delegation of updates to a contract
        ///
        access(all) fun delegate(updaterCap: Capability<&Updater>) {
            pre {
                updaterCap.check(): "Invalid DelegatedUpdater Capability!"
                updaterCap.borrow()!.hasBeenUpdated() == false: "Updater has already been updated!"
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
            emit UpdaterDelegationChanged(
                updaterUUID: id,
                updaterAddress: updaterCap.borrow()?.owner?.address,
                delegated: false
            )
        }
    }

    /// Returns the Address of the Delegatee associated with this contract
    ///
    access(all) fun getContractDelegateeAddress(): Address {
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
                    StagedContractUpdates.ContractUpdate(
                        address: address,
                        name: nameAndCode.keys[0],
                        code: nameAndCode.values[0]
                    )
                )
            }

            deployments.append(
                contractUpdates
            )
        }

        return deployments
    }

    /// Returns a new Host resource
    ///
    access(all) fun createNewHost(accountCap: Capability<&AuthAccount>): @Host {
        return <- create Host(accountCapability: accountCap)
    }

    /// Returns a new Updater resource
    ///
    access(all) fun createNewUpdater(
        blockUpdateBoundary: UInt64,
        hosts: [Capability<&Host>],
        deployments: [[ContractUpdate]]
    ): @Updater {
        let updater <- create Updater(blockUpdateBoundary: blockUpdateBoundary, hosts: hosts, deployments: deployments)
        emit UpdaterCreated(updaterUUID: updater.uuid, blockUpdateBoundary: blockUpdateBoundary)
        return <- updater
    }

    /// Creates a new Delegatee resource enabling caller to self-host their Delegatee
    ///
    access(all) fun createNewDelegatee(): @Delegatee {
        return <- create Delegatee()
    }

    init() {

        let contractAddress = self.account.address.toString()
        self.inboxHostCapabilityNamePrefix = "StagedContractUpdatesHostCapability_"

        self.HostStoragePath = StoragePath(identifier: "StagedContractUpdatesHost_".concat(contractAddress))!
        // self.HostPrivatePath = PrivatePath(identifier: "StagedContractUpdatesHost_".concat(contractAddress))!
        self.UpdaterStoragePath = StoragePath(identifier: "StagedContractUpdatesUpdater_".concat(contractAddress))!
        // self.DelegatedUpdaterPrivatePath = PrivatePath(identifier: "StagedContractUpdatesDelegatedUpdater_".concat(contractAddress))!
        self.UpdaterPublicPath = PublicPath(identifier: "StagedContractUpdatesUpdaterPublic_".concat(contractAddress))!
        // self.UpdaterContractAccountPrivatePath = PrivatePath(identifier: "UpdaterContractAccount_".concat(contractAddress))!
        self.DelegateeStoragePath = StoragePath(identifier: "StagedContractUpdatesDelegatee_".concat(contractAddress))!
        // self.DelegateePrivatePath = PrivatePath(identifier: "StagedContractUpdatesDelegatee_".concat(contractAddress))!
        self.DelegateePublicPath = PublicPath(identifier: "StagedContractUpdatesDelegateePublic_".concat(contractAddress))!

        self.account.save(<-create Delegatee(), to: self.DelegateeStoragePath)
        self.account.link<&{DelegateePublic}>(self.DelegateePublicPath, target: self.DelegateeStoragePath)
    }
}
