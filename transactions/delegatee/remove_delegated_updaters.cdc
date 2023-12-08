import "StagedContractUpdates"

/// Removes Updater Capabilities with given IDs from the signer's Delegatee
///
transaction(removeIDs: [UInt64]) {
    
    let delegatee: &StagedContractUpdates.Delegatee
    
    prepare(signer: AuthAccount) {
        self.delegatee = signer.borrow<&StagedContractUpdates.Delegatee>(from: StagedContractUpdates.DelegateeStoragePath)
            ?? panic("Could not borrow Delegatee reference from signer")
    }

    execute {
        for id in removeIDs {
            self.delegatee.removeDelegatedUpdater(id: id)
        }
    }
}
