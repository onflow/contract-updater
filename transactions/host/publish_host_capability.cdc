#allowAccountLinking

import "StagedContractUpdates"

/// Links the signer's AuthAccount and encapsulates in a Host resource, publishing a Host Capability for the specified
/// recipient. This would enable the recipient to execute arbitrary contract updates on the signer's behalf.
///
transaction(publishFor: Address) {

    prepare(signer: auth(BorrowValue, CopyValue, IssueAccountCapabilityController, IssueStorageCapabilityController, PublishInboxCapability, SaveValue) &Account) {

        // Derive paths for AuthAccount & Host Capabilities, identifying the recipient on publishing
        let accountCapStoragePath = StoragePath(
                identifier: "StagedContractUpdatesAccountCap_".concat(signer.address.toString())
            )!
        let hostCapStoragePath = StoragePath(identifier: "StagedContractUpdatesHostCap_".concat(publishFor.toString()))!

        var accountCap: Capability<auth(UpdateContract) &Account>? = nil
        // Setup Capability on underlying signing host account
        if signer.storage.type(at: accountCapStoragePath) == nil {
            accountCap = signer.capabilities.account.issue<auth(UpdateContract) &Account>()
            signer.storage.save(accountCap, to: accountCapStoragePath)
        } else {
            accountCap = signer.storage.copy<Capability<auth(UpdateContract) &Account>>(from: accountCapStoragePath)
                ?? panic("Invalid object retrieved from: ".concat(accountCapStoragePath.toString()))
        }

        assert(accountCap != nil && accountCap!.check(), message: "Invalid AuthAccount Capability retrieved")

        // Setup Host resource, wrapping the previously configured account capabaility
        if signer.storage.type(at: StagedContractUpdates.HostStoragePath) == nil {
            signer.storage.save(
                <- StagedContractUpdates.createNewHost(accountCap: accountCap!),
                to: StagedContractUpdates.HostStoragePath
            )
        }
        var hostCap: Capability<&StagedContractUpdates.Host>? = nil
        if signer.storage.type(at: hostCapStoragePath) == nil {
            signer.storage.save(
                signer.capabilities.storage.issue<&StagedContractUpdates.Host>(StagedContractUpdates.HostStoragePath),
                to: hostCapStoragePath
            )
        }
        hostCap = signer.storage.copy<Capability<&StagedContractUpdates.Host>>(from: hostCapStoragePath)
            ?? panic("Invalid object retrieved from: ".concat(hostCapStoragePath.toString()))

        assert(hostCap != nil && hostCap!.check(), message: "Invalid Host Capability retrieved")

        // Finally publish the Host Capability to the account that will store the Updater
        signer.inbox.publish(
            hostCap!,
            name: StagedContractUpdates.inboxHostCapabilityNamePrefix.concat(publishFor.toString()),
            recipient: publishFor
        )
    }
}
