import "MigrationContractStaging"

#interaction (
    version: "1.0.0",
    title: "Get Staged ContractUpdate",
    description:
        "Returns the ContractUpdate struct containing the staged update info for the given contract name and address or nil if not yet staged",
    language: "en-US",
)

/// Retrieves the ContractUpdate struct for the given contract name and address from MigrationContractStaging
/// A return value of nil indicates that no update is staged for the given contract
///
access(all) fun main(address: Address, name: String): MigrationContractStaging.ContractUpdate? {
    return MigrationContractStaging.getStagedContractUpdate(address: address, name: name)
}
