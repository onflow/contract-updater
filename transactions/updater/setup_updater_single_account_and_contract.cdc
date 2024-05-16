import "ViewResolver"

import "StagedContractUpdates"

/// Configures an Updater resource, assuming signing account is the account with the contract to update. This demos a
/// simple case where the signer is the deployment account and deployment only includes a single contract.
///
transaction(blockHeightBoundary: UInt64?, contractName: String, code: String) {

    prepare(signer: auth(BorrowValue, CopyValue, SaveValue, IssueAccountCapabilityController, IssueStorageCapabilityController, ClaimInboxCapability, PublishCapability) &Account) {

        // Ensure Updater has not already been configured at expected path
        // Note: If one was already configured, we'd want to load & destroy, but such action should be taken explicitly
        if signer.storage.type(at: StagedContractUpdates.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }
        // Continue configuration...

        // Derive paths for AuthAccount & Host Capabilities, identifying the recipient on publishing
        let accountCapStoragePath = StoragePath(
                identifier: "StagedContractUpdatesAccountCap_".concat(signer.address.toString())
            )!
        let hostCapStoragePath = StoragePath(
                identifier: "StagedContractUpdatesHostCap_".concat(signer.address.toString())
            )!

        var accountCap: Capability<auth(UpdateContract) &Account>? = nil
        // Setup Capability on underlying signing host account
        if signer.storage.type(at: accountCapStoragePath) == nil {
            accountCap = signer.capabilities.account.issue<auth(UpdateContract) &Account>()
            signer.storage.save(accountCap, to: accountCapStoragePath)
        } else {
            accountCap = signer.storage.copy<Capability<auth(UpdateContract) &Account>>(from: accountCapStoragePath)
                ?? panic("Invalid object retrieved from: ".concat(accountCapStoragePath.toString()))
        }

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

        // Create Updater resource, assigning the contract .blockUpdateBoundary to the new Updater
        signer.storage.save(
            <- StagedContractUpdates.createNewUpdater(
                blockUpdateBoundary: blockHeightBoundary ?? StagedContractUpdates.blockUpdateBoundary,
                hosts: [hostCap!],
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
        let updaterCap = signer.capabilities.storage.issue<&{StagedContractUpdates.UpdaterPublic, ViewResolver.Resolver}>(
            StagedContractUpdates.UpdaterStoragePath
        )
        signer.capabilities.publish(updaterCap, at: StagedContractUpdates.UpdaterPublicPath)
    }
}
