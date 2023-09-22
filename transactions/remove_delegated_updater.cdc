import "ContractUpdater"

transaction(removeID: UInt64) {
    
    let delegatee: &ContractUpdater.Delegatee
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.delegatee = signer.storge.borrow<&ContractUpdater.Delegatee>(from: ContractUpdater.DelegateeStoragePath)
            ?? panic("Could not borrow Delegatee reference from signer")
    }

    execute {
        self.delegatee.removeDelegatedUpdater(id: removeID)
    }
}