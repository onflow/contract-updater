import "StagedContractUpdates"

/// Allows the contract Coordinator to set a new blockUpdateBoundary
///
transaction(newBoundary: UInt64) {

    let coordinator: &StagedContractUpdates.Coordinator

    prepare(signer: AuthAccount) {
        self.coordinator = signer.borrow<&StagedContractUpdates.Coordinator>(
                from: StagedContractUpdates.CoordinatorStoragePath
            ) ?? panic("Could not borrow reference to Coordinator!")
    }

    execute {
        self.coordinator.setBlockUpdateBoundary(new: newBoundary)
    }

    post {
        StagedContractUpdates.blockUpdateBoundary == newBoundary: "Problem setting block update boundary"
    }
}
