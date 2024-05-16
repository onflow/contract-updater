import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Is Contract Staged Query",
    description: "Returns whether a contract is staged or not",
    language: "en-US",
)

/// Returns whether the given contract is staged or not
///
access(all) fun main(contractAddress: Address, contractName: String): Bool {
    return MigrationContractStaging.isStaged(address: contractAddress, name: contractName)
}
