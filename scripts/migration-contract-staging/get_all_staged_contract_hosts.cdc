import "MigrationContractStaging"

/// Returns the code for all staged contracts hosted by the given contract address.
///
access(all) fun main(): [Address] {
    return MigrationContractStaging.getAllStagedContractHosts()
}
