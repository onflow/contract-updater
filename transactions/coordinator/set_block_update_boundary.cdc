import "StagedContractUpdates"

/// Allows the contract Coordinator to set a new blockUpdateBoundary
///
transaction(newBoundary: UInt64) {
    prepare(signer: AuthAccount) {
        signer.borrow<&StagedContractUpdates.Coordinator>(from: StagedContractUpdates.CoordinatorStoragePath)
            ?.setBlockUpdateBoundary(new: newBoundary)
            ?? panic("No Coordinator in found!")
    }
}
