import "StagedContractUpdates"

/// Creates a private Updater Capability and gives it to the StagedContractUpdates Delegatee
///
transaction {

    let delegatee: &{StagedContractUpdates.DelegateePublic}
    let updaterCap: Capability<&StagedContractUpdates.Updater>
    let updaterID: UInt64

    prepare(signer: auth(BorrowValue, CopyValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

        // Revert if the signer doesn't already have an Updater configured
        if signer.storage.type(at: StagedContractUpdates.UpdaterStoragePath) == nil {
            panic("Signer does not have an Updater configured")
        }
        // Continue...

        // Get reference to the contract's DelegateePublic
        self.delegatee = StagedContractUpdates.getContractDelegateeCapability().borrow()
            ?? panic("Could not borrow Delegatee reference")

        let updaterCapStoragePath = StoragePath(
                identifier: "StagedContractUpdatesUpdaterCapability_".concat(
                    self.delegatee.owner?.address?.toString() ?? panic("Problem referencing contract's DelegateePublic owner address")
                )
            )!

        // Issue Updater Capability if needed, store & retrieve
        if signer.storage.type(at: updaterCapStoragePath) == nil {
            signer.storage.save(
                signer.capabilities.storage.issue<&StagedContractUpdates.Updater>(StagedContractUpdates.UpdaterStoragePath),
                to: updaterCapStoragePath
            )
        }
        self.updaterCap = signer.storage.copy<Capability<&StagedContractUpdates.Updater>>(from: updaterCapStoragePath)
            ?? panic("Problem retrieving Updater Capability")
        assert(self.updaterCap.check(), message: "Invalid Updater Capability retrieved")
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