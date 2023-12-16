import "StagedContractUpdates"

access(all) fun main(): UInt64? {
    return StagedContractUpdates.getContractDelegateeCapability().borrow()?.getBlockUpdateBoundary() ?? nil
}
