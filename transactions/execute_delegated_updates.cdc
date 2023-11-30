import "StagedContractUpdates"

transaction {
    
    let delegatee: &StagedContractUpdates.Delegatee
    
    prepare(signer: AuthAccount) {
        self.delegatee = signer.borrow<&StagedContractUpdates.Delegatee>(from: StagedContractUpdates.DelegateeStoragePath)
            ?? panic("Could not borrow Delegatee reference from signer")
    }

    execute {
        self.delegatee.update(updaterIDs: self.delegatee.getUpdaterIDs())
    }
}