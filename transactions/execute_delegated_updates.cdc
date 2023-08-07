import "ContractUpdater"

transaction {
    
    let delegatee: &ContractUpdater.Delegatee
    
    prepare(signer: AuthAccount) {
        self.delegatee = signer.borrow<&ContractUpdater.Delegatee>(from: ContractUpdater.DelegateeStoragePath)
            ?? panic("Could not borrow Delegatee reference from signer")
    }

    execute {
        self.delegatee.update(updaterIDs: self.delegatee.getUpdaterIDs())
    }
}