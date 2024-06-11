import "StagedContractUpdates"

/// Removes Updater Capabilities with given IDs from the signer's Delegatee
///
transaction(removeIDs: [UInt64]) {
    
    let delegatee: auth(Remove) &StagedContractUpdates.Delegatee
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.delegatee = signer.storage.borrow<auth(Remove) &StagedContractUpdates.Delegatee>(
                from: StagedContractUpdates.DelegateeStoragePath
            ) ?? panic("Could not borrow Delegatee reference from signer")
    }

    execute {
        for id in removeIDs {
            self.delegatee.removeDelegatedUpdater(id: id)
        }
    }
}
