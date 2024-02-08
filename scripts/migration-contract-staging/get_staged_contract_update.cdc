import "MigrationContractStaging"

access(all) fun main(address: Address, name: String): MigrationContractStaging.ContractUpdate? {
    return MigrationContractStaging.getStagedContractUpdate(address: address, name: name)
}
