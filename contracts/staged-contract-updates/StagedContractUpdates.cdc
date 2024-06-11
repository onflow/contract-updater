import "MetadataViews"
import "ViewResolver"

/// This contract defines resources which enable storage of contract code for the purposes of updating at or beyond
/// some blockheight boundary either by the containing resource's owner or by some delegated party.
///
/// The two primary resources involved in this are the @Updater and @Delegatee resources. As their names suggest, the
/// @Updater contains Capabilities for all deployment accounts (wrapped in @Host resources) as well as the
/// corresponding contract code + names in the order of their update deployment as well as a blockheight at or beyond
/// which the update can be performed. The @Delegatee resource can receive Capabilities to the @Updater resource and
/// can perform the update on behalf of the @Updater resource's owner.
///
/// For more info, see FLIP 179: https://github.com/onflow/flips/blob/main/application/20230809-staged-contract-updates.md
///
access(all) contract StagedContractUpdates {

    /// Common inbox name prefix for Host Capabilities
    access(all) let inboxHostCapabilityNamePrefix: String

    /// Common update boundary for those coordinating with contract account-managed Delegatee, enabling opt-in
    /// Flow coordinated contract updates
    access(all) var blockUpdateBoundary: UInt64

    /* --- Canonical Paths --- */
    //
    access(all) let HostStoragePath: StoragePath
    access(all) let UpdaterStoragePath: StoragePath
    access(all) let UpdaterPublicPath: PublicPath
    access(all) let DelegateeStoragePath: StoragePath
    access(all) let DelegateePublicPath: PublicPath
    access(all) let CoordinatorStoragePath: StoragePath

    /* --- Events --- */
    //
    /// Event emitted when the contract block update boundary is updated
    access(all) event ContractBlockUpdateBoundaryUpdated(old: UInt64?, new: UInt64)
    /// Event emitted when an Updater is created
    access(all) event UpdaterCreated(updaterUUID: UInt64, blockUpdateBoundary: UInt64)
    /// Event emitted when an Updater is updated
    access(all) event UpdaterUpdated(
        updaterUUID: UInt64,
        updaterAddress: Address?,
        blockUpdateBoundary: UInt64,
        stageUpdated: Int,
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

    /// Represents the status of an Updater resource, mirroring the encapsulated values of an Updater resource and
    /// defined here for ease of querying via MetadataViews.ViewResolver interface
    ///
    access(all) struct UpdaterInfo {
        access(all) let id: UInt64
        access(all) let blockUpdateBoundary: UInt64
        access(all) let updateComplete: Bool
        access(all) let hostAddresses: [Address]
        access(all) let deployments: [[ContractUpdate]]
        access(all) let currentDeploymentStage: Int
        access(all) let failedDeployments: {Int: [String]}

        init(
            id: UInt64,
            blockUpdateBoundary: UInt64,
            updateComplete: Bool,
            hostAddresses: [Address],
            deployments: [[ContractUpdate]],
            currentDeploymentStage: Int,
            failedDeployments: {Int: [String]}
        ) {
            self.id = id
            self.blockUpdateBoundary = blockUpdateBoundary
            self.updateComplete = updateComplete
            self.hostAddresses = hostAddresses
            self.deployments = deployments
            self.currentDeploymentStage = currentDeploymentStage
            self.failedDeployments = failedDeployments
        }
    }

    /* --- Host --- */
    //
    /// Encapsulates an Account, exposing only the ability to update contracts on the underlying account
    ///
    access(all) resource Host {
        access(self) let accountCapability: Capability<auth(UpdateContract) &Account>

        init(accountCapability: Capability<auth(UpdateContract) &Account>) {
            self.accountCapability = accountCapability
        }

        /// Updates the contract with the specified name and code
        ///
        access(UpdateContract) fun update(name: String, code: [UInt8]): Bool {
            if let account = self.accountCapability.borrow() {
                // TODO: Replace update__experimental with tryUpdate() once it's available
                // let deploymentResult = account.contracts.tryUpdate(name: name, code: code)
                // return deploymentResult.success
                account.contracts.tryUpdate(name: name, code: code)
                return true
            }
            return false
        }

        /// Checks the wrapped Account Capability
        ///
        access(all) view fun checkAccountCapability(): Bool {
            return self.accountCapability.check()
        }

        /// Returns the Address of the underlying account
        ///
        access(all) view fun getHostAddress(): Address? {
            return self.accountCapability.borrow()?.address
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
        access(all) view fun getInvalidHosts(): [Address]
    }

    /// Resource that enables delayed contract updates to a wrapped account at or beyond a specified block height
    ///
    access(all) resource Updater : UpdaterPublic, ViewResolver.Resolver {
        /// Update to occur at or beyond this block height
        access(self) let blockUpdateBoundary: UInt64
        /// Update status defining whether all update stages have been *attempted*
        /// NOTE: `true` does not necessarily mean all updates were successful
        access(self) var updateComplete: Bool
        /// Capabilities for contract hosting accounts
        access(self) let hosts: {Address: Capability<auth(UpdateContract) &Host>}
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
            hosts: [Capability<auth(UpdateContract) &Host>],
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
        access(UpdateContract) fun update(): Bool? {
            // Return early if we've already updated
            if self.updateComplete {
                return true
            } else if getCurrentBlock().height < self.blockUpdateBoundary {
                // Return nil to indicate we're not yet at the update boundary for this Updater
                return nil
            }

            let currentStage = self.currentDeploymentStage
            self.currentDeploymentStage = self.currentDeploymentStage + 1

            self.updateComplete = self.currentDeploymentStage == self.deployments.length

            let updatedAddresses: [Address] = []
            let failedAddresses: [Address] = []
            let updatedContracts: [String] = []
            let failedContracts: [String] = []

            for contractUpdate in self.deployments[currentStage] {
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
                self.failedDeployments.insert(key: currentStage, failedContracts)
            }

            emit UpdaterUpdated(
                updaterUUID: self.uuid,
                updaterAddress: self.owner?.address,
                blockUpdateBoundary: self.blockUpdateBoundary,
                stageUpdated: currentStage,
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
            return self.hosts.keys
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

        access(all) view fun getInvalidHosts(): [Address] {
            var invalidHosts: [Address] = []
            for host in self.hosts.values {
                if !host.check() || !host.borrow()!.checkAccountCapability() {
                    invalidHosts = invalidHosts.concat([host.address])
                }
            }
            return invalidHosts
        }

        /* --- MetadataViews.Resolver --- */

        access(all) view fun getViews(): [Type] {
            return [Type<UpdaterInfo>()]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            if view == Type<UpdaterInfo>() {
                return UpdaterInfo(
                    id: self.uuid,
                    blockUpdateBoundary: self.getBlockUpdateBoundary(),
                    updateComplete: self.hasBeenUpdated(),
                    hostAddresses: self.getContractAccountAddresses(),
                    deployments: self.getDeployments(),
                    currentDeploymentStage: self.getCurrentDeploymentStage(),
                    failedDeployments: self.getFailedDeployments()
                )
            }
            return nil
        }
    }
    
    /* --- Delegatee --- */
    //
    /// Public interface for Delegatee
    ///
    access(all) resource interface DelegateePublic {
        access(all) view fun check(id: UInt64): Bool?
        access(all) view fun getUpdaterIDs(): [UInt64]
        access(all) fun delegate(updaterCap: Capability<auth(UpdateContract) &Updater>)
        access(all) fun removeAsUpdater(updaterCap: Capability<auth(UpdateContract) &Updater>)
    }

    /// Resource capable of executed delegated updates via encapsulated Updater Capabilities
    ///
    access(all) resource Delegatee : DelegateePublic {
        /// Block height at which delegated updates will be performed by this Delegatee
        /// NOTE: This may differ from the contract's blockUpdateBoundary, enabling flexibility but any Updaters not
        ///     ready when updates are performed will be revoked from the Delegatee
        access(self) let blockUpdateBoundary: UInt64
        /// Mapping of all delegated Updater Capabilities by their UUID
        access(self) let delegatedUpdaters: {UInt64: Capability<auth(UpdateContract) &Updater>}

        init(blockUpdateBoundary: UInt64) {
            self.blockUpdateBoundary = blockUpdateBoundary
            self.delegatedUpdaters = {}
        }

        /// Checks if the specified DelegatedUpdater Capability is contained and valid
        ///
        access(all) view fun check(id: UInt64): Bool? {
            return self.delegatedUpdaters[id]?.check() ?? nil
        }

        /// Returns the IDs of delegated Updaters
        ///
        access(all) view fun getUpdaterIDs(): [UInt64] {
            return self.delegatedUpdaters.keys
        }

        /// Allows for the delegation of contract updates as defined within the Updater resource
        ///
        access(all) fun delegate(updaterCap: Capability<auth(UpdateContract) &Updater>) {
            pre {
                getCurrentBlock().height < self.blockUpdateBoundary:
                    "Delegation must occur before Delegatee boundary of ".concat(self.blockUpdateBoundary.toString())
                updaterCap.check(): "Invalid DelegatedUpdater Capability!"
                updaterCap.borrow()!.hasBeenUpdated() == false: "Updater has already been updated!"
                updaterCap.borrow()!.getBlockUpdateBoundary() <= self.blockUpdateBoundary:
                    "Updater will not be ready for updates at Delegatee boundary of ".concat(self.blockUpdateBoundary.toString())
            }

            let updater: &StagedContractUpdates.Updater = updaterCap.borrow()!
            if self.delegatedUpdaters.containsKey(updater.getID()) {
                // Upsert if updater Capability already contained
                self.delegatedUpdaters[updater.getID()] = updaterCap
            } else {
                // Insert if updater Capability not yet contained
                self.delegatedUpdaters.insert(key: updater.getID(), updaterCap)
            }
            emit UpdaterDelegationChanged(updaterUUID: updater.getID(), updaterAddress: updater.owner?.address, delegated: true)
        }

        /// Enables Updaters to remove their delegation
        ///
        access(all) fun removeAsUpdater(updaterCap: Capability<auth(UpdateContract) &Updater>) {
            pre {
                updaterCap.check(): "Invalid DelegatedUpdater Capability!"
                self.delegatedUpdaters.containsKey(updaterCap.borrow()!.getID()): "No Updater found for ID!"
            }

            let updater: &StagedContractUpdates.Updater = updaterCap.borrow()!
            self.removeDelegatedUpdater(id: updater.getID())
        }

        /// Executes update on the specified Updaters. All updates are attempted, and if the Updater is not yet ready
        /// to be updated (updater.update() returns nil) or the attempted update is the final staged (updater.update()
        /// returns true), the corresponding Updater Capability is removed.
        ///
        access(UpdateContract) fun update(updaterIDs: [UInt64]) {
            for id in updaterIDs {
                // Invalid ID - mark as purged and continue
                if self.delegatedUpdaters[id] == nil {
                    continue
                }

                // Check Capability - if invalid, remove Capability, mark as purged and continue
                let updaterCap: Capability<auth(UpdateContract) &StagedContractUpdates.Updater> = self.delegatedUpdaters[id]!
                if !updaterCap.check() {
                    self.delegatedUpdaters.remove(key: id)
                    continue
                }

                // Execute currently staged update
                let success: Bool? = updaterCap.borrow()!.update()
                // If update is not ready or complete, remove Capability and continue
                if success == nil || success! == true {
                    self.delegatedUpdaters.remove(key: id)
                    continue
                }
            }
        }

        /// Enables admin removal of a Updater Capability
        ///
        access(Remove) fun removeDelegatedUpdater(id: UInt64) {
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

    /* --- Coordinator --- */
    //
    /// This resource coordinates block update boundaries for all who opt-in to coordinated updates
    ///
    access(all) resource Coordinator {
        /// Allows the contract block update boundary to be set
        ///
        access(all) fun setBlockUpdateBoundary(new: UInt64) {
            pre {
                new > getCurrentBlock().height: "New boundary must be in the future!"
                new > StagedContractUpdates.blockUpdateBoundary: "New block update boundary must be greater than current boundary!"
            }
            let old = StagedContractUpdates.blockUpdateBoundary
            StagedContractUpdates.blockUpdateBoundary = new
            emit ContractBlockUpdateBoundaryUpdated(old: old, new: new)
        }
    }

    /* --- Contract Methods --- */

    /// Returns a Capability on the Delegatee associated with this contract
    ///
    access(all) fun getContractDelegateeCapability(): Capability<&{DelegateePublic}> {
        let delegateeCap = self.account.capabilities.get<&{DelegateePublic}>(self.DelegateePublicPath)
        assert(delegateeCap.check(), message: "Invalid Delegatee Capability retrieved")
        return delegateeCap
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
    access(all) fun createNewHost(accountCap: Capability<auth(UpdateContract) &Account>): @Host {
        return <- create Host(accountCapability: accountCap)
    }

    /// Returns a new Updater resource encapsulating the given hosts and deployments
    ///
    access(all) fun createNewUpdater(
        blockUpdateBoundary: UInt64,
        hosts: [Capability<auth(UpdateContract) &Host>],
        deployments: [[ContractUpdate]]
    ): @Updater {
        let updater <- create Updater(blockUpdateBoundary: blockUpdateBoundary, hosts: hosts, deployments: deployments)
        emit UpdaterCreated(updaterUUID: updater.uuid, blockUpdateBoundary: blockUpdateBoundary)
        return <- updater
    }

    /// Creates a new Delegatee resource enabling caller to self-host their Delegatee to be executed at or beyond
    /// given block update boundary
    ///
    access(all) fun createNewDelegatee(blockUpdateBoundary: UInt64): @Delegatee {
        return <- create Delegatee(blockUpdateBoundary: blockUpdateBoundary)
    }

    init(blockUpdateBoundary: UInt64) {
        let contractAddress = self.account.address.toString()

        self.blockUpdateBoundary = blockUpdateBoundary
        self.inboxHostCapabilityNamePrefix = "StagedContractUpdatesHostCapability_"

        self.HostStoragePath = StoragePath(identifier: "StagedContractUpdatesHost_".concat(contractAddress))!
        self.UpdaterStoragePath = StoragePath(identifier: "StagedContractUpdatesUpdater_".concat(contractAddress))!
        self.UpdaterPublicPath = PublicPath(identifier: "StagedContractUpdatesUpdaterPublic_".concat(contractAddress))!
        self.DelegateeStoragePath = StoragePath(identifier: "StagedContractUpdatesDelegatee_".concat(contractAddress))!
        self.DelegateePublicPath = PublicPath(identifier: "StagedContractUpdatesDelegateePublic_".concat(contractAddress))!
        self.CoordinatorStoragePath = StoragePath(identifier: "StagedContractUpdatesCoordinator_".concat(contractAddress))!

        self.account.storage.save(<-create Delegatee(blockUpdateBoundary: blockUpdateBoundary), to: self.DelegateeStoragePath)
        let delegateePublicCap = self.account.capabilities.storage.issue<&{DelegateePublic}>(self.DelegateeStoragePath)
        self.account.capabilities.publish(delegateePublicCap, at: self.DelegateePublicPath)

        self.account.storage.save(<-create Coordinator(), to: self.CoordinatorStoragePath)

        emit ContractBlockUpdateBoundaryUpdated(old: nil, new: blockUpdateBoundary)
    }
} 
