import "MigrationContractStaging"

/// Returns all staged contracts as a mapping of address to an array of contract names
///
access(all) fun main(): {Address: [String]} {
    return MigrationContractStaging.getAllStagedContracts()
}
