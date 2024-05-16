import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Claim Published Host Capability",
    description: "Claims a Host Capability from the Host Capability provider and stores it at the provided storage path.",
    language: "en-US",
)

/// This transaction claims a Host Capability from the Host Capability provider and stores it at the provided storage
/// path.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
/// @param hostPublisher: The address of the account that published the Host Capability for the signer.
/// @param hostCapStoragePathIdentifier: The identifier used to derive the storage path where the Host Capability will
///     be saved.
///
transaction(hostPublisher: Address, hostCapStoragePathIdentifier: String) {
    
    prepare(signer: auth(ClaimInboxCapability, SaveValue) &Account) {
        // Claim the published Capability from the signer's inbox
        let inboxName = "MigrationContractStagingHost_".concat(signer.address.toString())
        let hostCap = signer.inbox.claim<&MigrationContractStaging.Host>(inboxName, provider: hostPublisher)
            ?? panic("Host Capability was not found in signer's inbox")

        assert(hostCap.check(), message: "The received Capability is invalid")

        // Store the Host Capability in the signer's storage, deriving the storage path on the publisher's address
        let storagePath = StoragePath(identifier: hostCapStoragePathIdentifier)
            ?? panic("Failed to derive the storage path from the provided identifier")
        signer.storage.save(hostCap, to: storagePath)
    }
}
