import "StagedContractUpdates"

transaction(blockUpdateBoundary: UInt64) {

    let delegatee: &StagedContractUpdates.Delegatee

    prepare(signer: AuthAccount) {
        self.delegatee = signer.borrow<&StagedContractUpdates.Delegatee>(from: StagedContractUpdates.DelegateeStoragePath)
            ?? panic("Could not borrow a reference to the signer's Delegatee")
    }

    execute {
        self.delegatee.setBlockUpdateBoundary(blockHeight: blockUpdateBoundary)
    }

    post {
        self.delegatee.getBlockUpdateBoundary() == blockUpdateBoundary: "Problem setting block update boundary"
    }
}
