import "MigrationContractStaging"

/// Retrieves the ContractUpdate struct for the given contract name and address from MigrationContractStaging
/// A return value of nil indicates that no update is staged for the given contract
///
access(all) fun main(address: Address, name: String): MigrationContractStaging.ContractUpdate? {
    return MigrationContractStaging.getStagedContractUpdate(address: address, name: name)
}
