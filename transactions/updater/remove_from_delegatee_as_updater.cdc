import "StagedContractUpdates"

/// Retrieves an Updater Capability from the signer's account, assuming one is pre-configured, and removes it from the
/// Delegatee in the StagedContractUpdates contract account.
///
transaction {
    
    let delegatee: &{StagedContractUpdates.DelegateePublic}
    let updaterCap: Capability<&StagedContractUpdates.Updater>
    let updaterID: UInt64
    
    prepare(signer: AuthAccount) {
        self.delegatee = StagedContractUpdates.getContractDelegateeCapability().borrow()
            ?? panic("Could not borrow Delegatee reference")

        let updaterPrivatePath = PrivatePath(
                identifier: "StagedContractUpdatesUpdater_".concat(
                    self.delegatee.owner?.address?.toString() ?? panic("Problem referencing contract's DelegateePublic owner address")
                )
            )!

        self.updaterCap = signer.getCapability<&StagedContractUpdates.Updater>(updaterPrivatePath)
        self.updaterID = self.updaterCap.borrow()?.getID() ?? panic("Invalid Updater Capability retrieved from signer!")
    }

    execute {
        self.delegatee.removeAsUpdater(updaterCap: self.updaterCap)
    }

    post {
        self.delegatee.check(id: self.updaterID) == nil: "Updater Capability was not properly removed from Delegatee"
    }
}
