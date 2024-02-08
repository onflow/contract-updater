import "MigrationContractStaging"

access(all) fun main(address: Address, name: String): Bool? {
    return MigrationContractStaging.getStagedContractUpdate(address: address, name: name)?.isValidated() ?? nil
}