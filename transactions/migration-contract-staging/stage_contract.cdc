#allowAccountLinking

import "MigrationContractStaging"

/// This transaction is used to stage a contract update for Cadence 1.0 contract migrations.
/// Ensure that this transaction is signed by the account that owns the contract to be updated and that the contract
/// has already been deployed to the signing account.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
/// @param contractName: The name of the contract to be updated with the given code
/// @param contractCode: The updated contract code as a hex-encoded String
///
transaction(contractName: String, contractCode: String) {
    let accountCapability: Capability<&AuthAccount>
    
    prepare(signer: AuthAccount) {
        // Retrieve an AuthAccount Capability to the signer's account
        let accountCapabilityPath: PrivatePath = MigrationContractStaging.deriveAccountCapabilityPath(
                forAddress: signer.address
            )
        if signer.getCapability<&AuthAccount>(accountCapabilityPath).borrow() == nil {
            self.accountCapability = signer.linkAccount(accountCapabilityPath) ?? panic("Problem linking account")
        } else {
            self.accountCapability = signer.getCapability<&AuthAccount>(accountCapabilityPath)
        }
        // Create a Host resource, wrapping the retrieved Account Capability
        let host: @MigrationContractStaging.Host <- MigrationContractStaging.createHost(
                accountCapability: self.accountCapability
            )
        
        // Create an Updater resource, staging the update
        let updaterStoragePath: StoragePath = MigrationContractStaging.deriveUpdaterStoragePath(
                contractAddress: signer.address,
                contractName: contractName
            )
        // Ensure that an Updater resource doesn't already exist for this contract. If so, revert. Signer should
        // inspect the existing Updater and destroy if needed before re-attempting this transaction
        assert(
            signer.borrow<&MigrationContractStaging.Updater>(from: updaterStoragePath) == nil,
            message: "Updater already exists"
        )
        signer.save(
            <-MigrationContractStaging.createUpdater(
                host: <-host,
                stagedUpdate: MigrationContractStaging.ContractUpdate(
                    address: signer.address,
                    name: contractName,
                    code: contractCode
                )
            ), to: updaterStoragePath
        )
        let updaterPublicPath: PublicPath = MigrationContractStaging.deriveUpdaterPublicPath(
                contractAddress: signer.address,
                contractName: contractName
            )
        signer.link<&MigrationContractStaging.Updater>(updaterPublicPath, target: updaterStoragePath)
    }
}
