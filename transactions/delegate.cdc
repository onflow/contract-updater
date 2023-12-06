import "StagedContractUpdates"

/// Creates a private Updater Capability and gives it to the StagedContractUpdates Delegatee
///
transaction {

    let delegatee: &{StagedContractUpdates.DelegateePublic}
    let updaterCap: Capability<&StagedContractUpdates.Updater>
    let updaterID: UInt64

    prepare(signer: AuthAccount) {

        // Revert if the signer doesn't already have an Updater configured
        if signer.type(at: StagedContractUpdates.UpdaterStoragePath) == nil {
            panic("Signer does not have an Updater configured")
        }
        // Continue...

        // Get reference to the contract's DelegateePublic
        self.delegatee = StagedContractUpdates.getContractDelegateeCapability().borrow()
            ?? panic("Could not borrow Delegatee reference")

        let updaterPrivatePath = PrivatePath(
                identifier: "StagedContractUpdatesUpdater_".concat(
                    self.delegatee.owner?.address?.toString() ?? panic("Problem referencing contract's DelegateePublic owner address")
                )
            )!

        // Link Updater Capability in private if needed & retrieve
        if !signer.getCapability<&StagedContractUpdates.Updater>(updaterPrivatePath).check() {
            signer.unlink(updaterPrivatePath)
            signer.link<&StagedContractUpdates.Updater>(
                updaterPrivatePath,
                target: StagedContractUpdates.UpdaterStoragePath
            )
        }
        self.updaterCap = signer.getCapability<&StagedContractUpdates.Updater>(updaterPrivatePath)
        self.updaterID = self.updaterCap.borrow()?.getID() ?? panic("Invalid Updater Capability retrieved from signer!")
    }

    execute {
        self.delegatee.delegate(updaterCap: self.updaterCap)
    }

    post {
        // Confirm successful delegation
        self.delegatee.check(id: self.updaterID) == true: "Updater Capability was not properly delegated"
    }
}