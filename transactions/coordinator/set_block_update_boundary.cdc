import "StagedContractUpdates"

/// Allows the contract Coordinator to set a new blockUpdateBoundary
///
transaction(newBoundary: UInt64) {
    prepare(signer: auth(BorrowValue) &Account) {
        signer.storage.borrow<&StagedContractUpdates.Coordinator>(from: StagedContractUpdates.CoordinatorStoragePath)
            ?.setBlockUpdateBoundary(new: newBoundary)
            ?? panic("Could not borrow reference to Coordinator!")
    }
}
