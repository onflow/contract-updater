import "StagedContractUpdates"

/// Retrieves an Updater Capability from the signer's account, assuming one is pre-configured, and removes it from the
/// Delegatee in the StagedContractUpdates contract account.
///
transaction {
    
    let delegatee: &{StagedContractUpdates.DelegateePublic}
    let updaterCap: Capability<auth(UpdateContract) &StagedContractUpdates.Updater>
    let updaterID: UInt64
    
    prepare(signer: auth(BorrowValue, CopyValue) &Account) {
        self.delegatee = StagedContractUpdates.getContractDelegateeCapability().borrow()
            ?? panic("Could not borrow Delegatee reference")

        let updaterPrivatePath = PrivatePath(
                identifier: "StagedContractUpdatesUpdater_".concat(
                    self.delegatee.owner?.address?.toString() ?? panic("Problem referencing contract's DelegateePublic owner address")
                )
            )!
        let updaterCapStoragePath = StoragePath(
                identifier: "StagedContractUpdatesUpdaterCapability_".concat(
                    self.delegatee.owner?.address?.toString() ?? panic("Problem referencing contract's DelegateePublic owner address")
                )
            )!

        self.updaterCap = signer.storage.copy<Capability<auth(UpdateContract) &StagedContractUpdates.Updater>>(from: updaterCapStoragePath)
            ?? panic("Problem retrieving Updater Capability")

        self.updaterID = self.updaterCap.borrow()?.getID() ?? panic("Invalid Updater Capability retrieved from signer!")
    }

    execute {
        self.delegatee.removeAsUpdater(updaterCap: self.updaterCap)
    }

    post {
        self.delegatee.check(id: self.updaterID) == nil: "Updater Capability was not properly removed from Delegatee"
    }
}
