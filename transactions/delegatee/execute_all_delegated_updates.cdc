import "StagedContractUpdates"

/// Updates all current stages of delegated contract updates in contained Updater Capabilities
/// Note: If there are enough Updaters delegated to the signer's Delegatee, this may need to be done in batches
/// due to transaction computation limits
///
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
