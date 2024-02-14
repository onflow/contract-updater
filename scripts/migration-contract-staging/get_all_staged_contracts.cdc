import "MigrationContractStaging"

#interaction (
    version: "1.0.0",
    title: "Get All Staged Contracts",
    description: "Returns a mapping of all staged contract updates.",
    language: "en-US",
)

/// Returns all staged contracts as a mapping of address to an array of contract names
///
access(all) fun main(): {Address: [String]} {
    return MigrationContractStaging.getAllStagedContracts()
}
