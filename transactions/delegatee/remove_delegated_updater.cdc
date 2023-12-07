import "StagedContractUpdates"

transaction(removeID: UInt64) {
    
    let delegatee: &StagedContractUpdates.Delegatee
    
    prepare(signer: AuthAccount) {
        self.delegatee = signer.borrow<&StagedContractUpdates.Delegatee>(from: StagedContractUpdates.DelegateeStoragePath)
            ?? panic("Could not borrow Delegatee reference from signer")
    }

    execute {
        self.delegatee.removeDelegatedUpdater(id: removeID)
    }
}