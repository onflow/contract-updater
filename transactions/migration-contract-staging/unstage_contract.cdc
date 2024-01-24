import "MigrationContractStaging"

/// Loads and destroys the existing updater for the given contract name in the signer's account if exists. This means
/// the contract will no longer be staged for migrated updates.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
transaction(contractName: String) {

    prepare(signer: AuthAccount) {
        let updaterStoragePath: StoragePath = MigrationContractStaging.deriveUpdaterStoragePath(
                contractAddress: signer.address,
                contractName: contractName
            )
        let updaterPublicPath: PublicPath = MigrationContractStaging.deriveUpdaterPublicPath(
                contractAddress: signer.address,
                contractName: contractName
            )
        signer.unlink(updaterPublicPath)
        destroy signer.load<@MigrationContractStaging.Updater>(from: updaterStoragePath)
    }
}
