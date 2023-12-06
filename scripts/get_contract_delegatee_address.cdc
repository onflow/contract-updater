import "StagedContractUpdates"

access(all) fun main(): Address {
    return StagedContractUpdates.getContractDelegateeAddress()
}