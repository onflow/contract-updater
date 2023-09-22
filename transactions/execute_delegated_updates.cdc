import "ContractUpdater"

transaction {
    
    let delegatee: &ContractUpdater.Delegatee
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.delegatee = signer.storage.borrow<&ContractUpdater.Delegatee>(from: ContractUpdater.DelegateeStoragePath)
            ?? panic("Could not borrow Delegatee reference from signer's storage")
    }

    execute {
        self.delegatee.update(updaterIDs: self.delegatee.getUpdaterIDs())
    }
}