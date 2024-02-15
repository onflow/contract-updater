import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Get All Staged Contract Code for Address",
    description: "Returns a mapping of all contract code staged for a given address indexed on the contract name.",
    language: "en-US",
)

/// Returns the code for all staged contracts hosted by the given contract address.
///
access(all) fun main(contractAddress: Address): {String: String} {
    return MigrationContractStaging.getAllStagedContractCode(forAddress: contractAddress)
}
