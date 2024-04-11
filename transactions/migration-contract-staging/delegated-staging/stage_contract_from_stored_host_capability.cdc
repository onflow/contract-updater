import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Stage Contract Update From Stored Host Capability",
    description: "Stages the provided contract code in the staging contract for Cadence 1.0 contract migrations. This particular transaction assumes a Host Capability has been saved in storage, as would be the case for accounts choosing to delegate staging functionality to a dev team.",
    language: "en-US",
)

/// This transaction is used to stage a contract update for Cadence 1.0 contract migrations via stored Host Capability.
///
/// Ensure that this transaction is signed by an account that has been granted and stores a Host Capability. The stored
/// Capability should target a Host in the account that owns the contract to be updated and that the contract has
/// already been deployed to the Host account.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
/// @param hostCapStoragePathIdentifier: The identifier used to derive the storage path where the Host Capability is
///     saved.
/// @param contractName: The name of the contract to be updated with the given code
/// @param contractCode: The updated contract code
///
transaction(hostCapStoragePathIdentifier: String, contractName: String, contractCode: String) {
    let host: &MigrationContractStaging.Host
    
    prepare(signer: AuthAccount) {
        // Copy the Capability from storage
        let storagePath = StoragePath(identifier: hostCapStoragePathIdentifier)
            ?? panic("Failed to derive the storage path from the provided identifier")
        let hostCap = signer.copy<Capability<&MigrationContractStaging.Host>>(from: storagePath)
            ?? panic("Missing Host capability in storage")
        self.host = hostCap.borrow() ?? panic("Host Cap in storage is invalid")
    }

    execute {
        // Call staging contract, storing the contract code that will update during Cadence 1.0 migration
        // If code is already staged for the given contract, it will be overwritten.
        MigrationContractStaging.stageContract(host: self.host, name: contractName, code: contractCode)
    }

    post {
        MigrationContractStaging.isStaged(address: self.host.address(), name: contractName):
            "Problem while staging update"
    }
}
