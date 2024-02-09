import "MigrationContractStaging"

/// Returns whether a contract update has been validated, returning nil if it isn't staged
///
access(all) fun main(address: Address, name: String): Bool? {
    return MigrationContractStaging.isValidated(address: address, name: name)
}
