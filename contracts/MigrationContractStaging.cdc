/// This contract is intended for use for the Cadence 1.0 contract migration across the Flow network.
///
/// To stage your contract for automated updates in preparation for Cadence 1.0, simply configure an Updater resource
/// in the contract account along with an AuthAccount Capability, the contract address, name and hex-encoded Cadence.
///
/// NOTE: Do not move the Updater resource from this account or unlink the Account Capability in your Host or you risk
///     breaking the automated update process for your contract.
///
access(all) contract MigrationContractStaging {

    // Path derivation constants
    //
    access(all) let delimiter: String
    access(all) let updaterPathPrefix: String
    access(all) let accountCapabilityPathPrefix: String

    /// Event emitted when an Updater is created
    /// NOTE: Does not guarantee that the Updater is properly configured or even exists beyond event emission
    access(all) event AccountContractStaged(
        updaterUUID: UInt64,
        address: Address,
        codeHash: [UInt8],
        contract: String
    )

    /* --- ContractUpdate --- */
    //
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

        /// Validates that the named contract exists at the target address
        ///
        access(all) view fun isValid(): Bool {
            return getAccount(self.address).contracts.names.contains(self.name)
        }

        /// Serializes the address and name into a string of the form 0xADDRESS.NAME
        ///
        access(all) view fun toString(): String {
            return self.address.toString().concat(".").concat(self.name)
        }

        /// Returns human-readable string of the Cadence code
        ///
        access(all) view fun codeAsCadence(): String {
            return String.fromUTF8(self.code.decodeHex()) ?? panic("Problem stringifying code!")
        }
    }

    /* --- Host --- */
    //
    /// Encapsulates an AuthAccount, exposing only the ability to update contracts on the underlying account
    ///
    access(all) resource Host {
        /// Capability on the underlying account, possession of which serves as proof of access on the account
        access(self) let accountCapability: Capability<&AuthAccount>

        init(accountCapability: Capability<&AuthAccount>) {
            self.accountCapability = accountCapability
        }

        /// Verifies that the encapsulated Account is the owner of this Host
        ///
        access(all) view fun isValid(): Bool {
            return self.getHostAddress() != nil && self.getHostAddress() == self.owner?.address
        }

        /// Checks the wrapped AuthAccount Capability
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
    /// Resource that enables staged contract updates to the Host account. In the context of the Cadence 1.0 migration,
    /// this Updater should be stored with a ContractUpdate in the account which is to be updated. An Updater should be
    /// configured for each contract in an account.
    ///
    access(all) resource Updater {
        /// The Host resource encapsulating the Account Capability
        access(self) let host: @Host
        /// The address, name and code of the contract that will be updated
        access(self) let stagedUpdate: ContractUpdate

        init(host: @Host, stagedUpdate: ContractUpdate) {
            pre {
                host.getHostAddress() == stagedUpdate.address: "Host and update address must match"
                stagedUpdate.codeAsCadence() != nil: "Staged update code must be valid Cadence"
                stagedUpdate.isValid(): "Target contract does not exist"
            }
            self.host <- host
            self.stagedUpdate = stagedUpdate
        }

        /// Returns whether the Updater is properly configured
        /// NOTE: Does NOT check that the staged contract code is valid!
        ///
        access(all) view fun isValid(): Bool {
            let statuses: {String: String} = self.systemsCheck()
            for status in statuses.values {
                if status != "PASSING" {
                    return false
                }
            }
            return true
        }

        /// Enables borrowing of a Host reference. Since all Host methods are view, this is safe to do.
        ///
        access(all) view fun borrowHost(): &Host {
            return &self.host as &Host
        }

        /// Returns the staged contract update in the form of a ContractUpdate struct
        ///
        access(all) view fun getContractUpdate(): ContractUpdate {
            return self.stagedUpdate
        }

        /// Checks all conditions **EXCEPT CODE VALIDITY** and reports back with a map of statuses for each check
        /// Platforms may utilize this method to display whether the Updater is properly configured in human-readable
        /// language
        ///
        access(all) view fun systemsCheck(): {String: String} {
            return {
                "Updater": self.checkUpdater(),
                "Host": self.checkHost(),
                "Staged Update": self.checkStagedUpdate(),
                "Contract Existence": self.checkTargetContractExists()
            }
        }

        /// Returns the status of the Updater based on conditions relevant to the Cadence 1.0 contract migration
        ///
        access(all) view fun checkUpdater(): String {
            if self.owner == nil {
                return "FAILING: Unowned Updater"
            } else if self.owner!.address == self.host.getHostAddress() &&
                self.owner!.address == self.stagedUpdate.address {
                return "PASSING"
            } else if self.owner!.address != self.stagedUpdate.address {
                return "FAILING: Owner address does not match staged Update target address"
            } else if self.owner!.address != self.host.getHostAddress() {
                return "FAILING: Owner address does not match Host address"
            } else {
                return "FAILING: Unknown error"
            }
        }

        /// Returns the status of the Host based on conditions relevant to the Cadence 1.0 contract migration
        ///
        access(all) view fun checkHost(): String {
            if self.host.isValid() {
                return "PASSING"
            } else if self.host.checkAccountCapability() == false {
                return "FAILING: Account Capability check failed"
            } else if self.owner == nil {
                return "FAILING: Unowned Updater"
            } else if self.host.getHostAddress()! != self.owner!.address {
                return "FAILING: Host address does not match owner address"
            } else {
                return "FAILING: Unknown error"
            }
        }

        /// Returns the status of the staged update based on conditions relevant to the Cadence 1.0 contract migration
        ///
        access(all) view fun checkStagedUpdate(): String {
            if self.stagedUpdate.address != self.host.getHostAddress() {
                return "FAILING: Staged Update address does not match Host address"
            } else if self.owner == nil {
                return "FAILING: Unowned Updater"
            } else if self.stagedUpdate.address == self.host.getHostAddress() {
                return "PASSING"
            } else {
                return "FAILING: Unknown error"
            }
        }

        /// Returns whether the staged contract exists on the target account. This is important as the contract
        /// migration only affects **existing** contracts
        ///
        access(all) view fun checkTargetContractExists(): String {
            if self.stagedUpdate.isValid() {
                return "PASSING"
            } else {
                return "FAILING: Target contract with name "
                    .concat(self.stagedUpdate.name)
                    .concat(" does not exist at address ")
                    .concat(self.stagedUpdate.address.toString())
            }
        }

        destroy() {
            destroy self.host
        }
    }

    /// Returns a StoragePath to store the Updater of the form:
    ///     /storage/self.updaterPathPrefix_ADDRESS_NAME
    access(all) fun deriveUpdaterStoragePath(contractAddress: Address, contractName: String): StoragePath {
        return StoragePath(
                identifier: self.updaterPathPrefix
                    .concat(self.delimiter)
                    .concat(contractAddress.toString())
                    .concat(self.delimiter)
                    .concat(contractName)
            ) ?? panic("Could not derive Updater StoragePath for given address")
    }

    /// Returns a PublicPath to store the Updater of the form:
    ///     /storage/self.updaterPathPrefix_ADDRESS_NAME
    access(all) fun deriveUpdaterPublicPath(contractAddress: Address, contractName: String): PublicPath {
        return PublicPath(
                identifier: self.updaterPathPrefix
                    .concat(self.delimiter)
                    .concat(contractAddress.toString())
                    .concat(self.delimiter)
                    .concat(contractName)
            ) ?? panic("Could not derive Updater PublicPath for given address")
    }

    /// Returns a PrivatePath to store the Account Capability of the form:
    ///     /storage/self.accountCapabilityPathPrefix_ADDRESS
    access(all) fun deriveAccountCapabilityPath(forAddress: Address): PrivatePath {
        return PrivatePath(
            identifier: self.accountCapabilityPathPrefix.concat(self.delimiter).concat(forAddress.toString())
        ) ?? panic("Could not derive Account Capability path for given address")
    }

    /// Creates a Host resource wrapping the given account capability
    ///
    access(all) fun createHost(accountCapability: Capability<&AuthAccount>): @Host {
        return <- create Host(accountCapability: accountCapability)
    }

    /// Creates an Updater resource with the given Host and ContractUpdate. Should be stored at the derived path in the
    /// target address - the same account the Host maintains an Account Capability for.
    ///
    access(all) fun createUpdater(host: @Host, stagedUpdate: ContractUpdate): @Updater {
        let updater: @MigrationContractStaging.Updater <- create Updater(host: <-host, stagedUpdate: stagedUpdate)
        emit AccountContractStaged(
            updaterUUID: updater.uuid,
            address: stagedUpdate.address,
            codeHash: stagedUpdate.code.decodeHex(),
            contract: stagedUpdate.name
        )
        return <- updater
    }

    init() {
        self.delimiter = "_"
        self.accountCapabilityPathPrefix = "MigrationContractStagingHostAccountCapability"
            .concat(self.delimiter)
            .concat(self.account.address.toString())
        self.updaterPathPrefix = "MigrationContractStagingUpdater"
            .concat(self.delimiter)
            .concat(self.account.address.toString())
    }
}
