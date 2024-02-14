import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Get Staged Contract Names for given Address",
    description: "Retrieves a list of contract names that are staged for the given address",
    language: "en-US",
)

/// Returns the names of all contracts staged by a certain address
///
access(all) fun main(contractAddress: Address): [String] {
    return MigrationContractStaging.getStagedContractNames(forAddress: contractAddress)
}
