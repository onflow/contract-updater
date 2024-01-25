import "MigrationContractStaging"

/// Returns the names of all contracts staged by a certain address
///
access(all) fun main(contractAddress: Address): [String] {
    return MigrationContractStaging.getStagedContractNames(forAddress: contractAddress)
}
