import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Setup Staging Host",
    description: "Configures a MigrationContractStaging Host in the signer's account. If an address is provided, a private Host Capability will be published for the given address, enabling the recipient to stage contracts on behalf of the signer.",
    language: "en-US",
)

/// This transaction can be used to setup a Host resource in the signer's account. If an address is provided, a private
/// Host Capability will be published for the given address, enabling the recipient to stage contracts on behalf of the
/// signer.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
/// @param hostCapabilityRecipient: The optional Address of the recipient that can claim the published Host Capability.
///     If the value is nil, no Host Capability linked or published.
///
transaction(hostCapabilityRecipient: Address?) {

    prepare(signer: auth(BorrowValue, SaveValue, GetStorageCapabilityController, IssueStorageCapabilityController, PublishInboxCapability) &Account) {
        // Configure Host resource if needed
        if signer.storage.borrow<&MigrationContractStaging.Host>(from: MigrationContractStaging.HostStoragePath) == nil {
            signer.storage.save(<-MigrationContractStaging.createHost(), to: MigrationContractStaging.HostStoragePath)
        }
        // Ensure Host resource is setup
        assert(
            signer.storage.type(at: MigrationContractStaging.HostStoragePath) == Type<@MigrationContractStaging.Host>(),
            message: "Failed to setup Host resource"
        )
        // Configure a private Host Capability & publish if a recipient is defined
        if hostCapabilityRecipient != nil {
            let hostIdentifier = "MigrationContractStagingHost_".concat(hostCapabilityRecipient!.toString())
            let hostCap = signer.capabilities.storage.issue<&MigrationContractStaging.Host>(
                MigrationContractStaging.HostStoragePath
            )
            assert(hostCap.check(), message: "Failed to issue Host Capability")
            signer.storage.save(hostCap, to: StoragePath(identifier: hostIdentifier)!)
            signer.inbox.publish(hostCap, name: hostIdentifier, recipient: hostCapabilityRecipient!)
        }
    }
}
