import "MigrationContractStaging"

#interaction (
    version: "1.0.0",
    title: "Get Staged Contract Code",
    description: "Returns the Cadence code that has been staged for the given contract or nil if it is not yet staged.",
    language: "en-US",
)

/// Returns the code as it is staged or nil if it not currently staged.
///
access(all) fun main(contractAddress: Address, contractName: String): String? {
    return MigrationContractStaging.getStagedContractCode(address: contractAddress, name: contractName)
}
