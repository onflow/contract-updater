#allowAccountLinking

import "StagedContractUpdates"

/// Links the signer's AuthAccount and encapsulates in a Host resource, publishing a Host Capability for the specified
/// recipient. This would enable the recipient to execute arbitrary contract updates on the signer's behalf.
///
transaction(publishFor: Address) {

    prepare(signer: AuthAccount) {

        // Derive paths for AuthAccount & Host Capabilities, identifying the recipient on publishing
        let accountCapPrivatePath = PrivatePath(
                identifier: "StagedContractUpdatesAccountCap_".concat(signer.address.toString())
            )!
        let hostPrivatePath = PrivatePath(identifier: "StagedContractUpdatesHost_".concat(publishFor.toString()))!

        // Setup Capability on underlying signing host account
        if !signer.getCapability<&AuthAccount>(accountCapPrivatePath).check() {
            signer.unlink(accountCapPrivatePath)
            signer.linkAccount(accountCapPrivatePath)
                ?? panic("Problem linking AuthAccount Capability")
        }
        let accountCap = signer.getCapability<&AuthAccount>(accountCapPrivatePath)

        assert(accountCap.check(), message: "Invalid AuthAccount Capability retrieved")

        // Setup Host resource, wrapping the previously configured account capabaility
        if signer.type(at: StagedContractUpdates.HostStoragePath) == nil {
            signer.save(
                <- StagedContractUpdates.createNewHost(accountCap: accountCap),
                to: StagedContractUpdates.HostStoragePath
            )
        }
        if !signer.getCapability<&StagedContractUpdates.Host>(hostPrivatePath).check() {
            signer.unlink(hostPrivatePath)
            signer.link<&StagedContractUpdates.Host>(hostPrivatePath, target: StagedContractUpdates.HostStoragePath)
        }
        let hostCap = signer.getCapability<&StagedContractUpdates.Host>(hostPrivatePath)

        assert(hostCap.check(), message: "Invalid Host Capability retrieved")

        // Finally publish the Host Capability to the account that will store the Updater
        signer.inbox.publish(
            hostCap,
            name: StagedContractUpdates.inboxHostCapabilityNamePrefix.concat(publishFor.toString()),
            recipient: publishFor
        )
    }
}
