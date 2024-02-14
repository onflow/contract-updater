import "MigrationContractStaging"

#interaction (
    version: "1.0.0",
    title: "Get All Staged Contract Hosts",
    description: "Returns an array containing the addresses of all contract hosting accounts that have staged contracts.",
    language: "en-US",
)

/// Returns the code for all staged contracts hosted by the given contract address.
///
access(all) fun main(): [Address] {
    return MigrationContractStaging.getAllStagedContractHosts()
}
