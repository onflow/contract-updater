#allowAccountLinking

import "MetadataViews"

import "StagedContractUpdates"

/// Configures an Updater resource, assuming signing account is the account with the contract to update. This demos a
/// simple case where the signer is the deployment account and deployment only includes a single contract.
///
transaction(blockHeightBoundary: UInt64?, contractName: String, code: String) {

    prepare(signer: AuthAccount) {

        // Ensure Updater has not already been configured at expected path
        // Note: If one was already configured, we'd want to load & destroy, but such action should be taken explicitly
        if signer.type(at: StagedContractUpdates.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }
        // Continue configuration...

        let accountCapPrivatePath: PrivatePath = /private/StagedContractUpdatesAccountCap
        let hostPrivatePath: PrivatePath = /private/StagedContractUpdatesHost

        // Setup Capability on underlying signing host account
        if !signer.getCapability<&AuthAccount>(accountCapPrivatePath).check() {
            signer.unlink(accountCapPrivatePath)
            signer.linkAccount(accountCapPrivatePath)
        }
        let accountCap = signer.getCapability<&AuthAccount>(accountCapPrivatePath)

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

        if blockHeightBoundary == nil && StagedContractUpdates.blockUpdateBoundary == nil {
            // TODO: THIS IS A PROBLEM - Can't setup Updater without a contract blockHeightBoundary
            // Maybe alt is to set to now + 1?
            panic("Contract update boundary is not yet set, must specify blockHeightBoundary if not coordinating")
        }
        // Create Updater resource, assigning the contract .blockUpdateBoundary to the new Updater
        signer.save(
            <- StagedContractUpdates.createNewUpdater(
                blockUpdateBoundary: blockHeightBoundary ?? StagedContractUpdates.blockUpdateBoundary!,
                hosts: [hostCap],
                deployments: [[
                    StagedContractUpdates.ContractUpdate(
                        address: signer.address,
                        name: contractName,
                        code: code
                    )
                ]]
            ),
            to: StagedContractUpdates.UpdaterStoragePath
        )
        signer.unlink(StagedContractUpdates.UpdaterPublicPath)
        signer.link<&{StagedContractUpdates.UpdaterPublic, MetadataViews.Resolver}>(
            StagedContractUpdates.UpdaterPublicPath,
            target: StagedContractUpdates.UpdaterStoragePath
        )
    }
}
