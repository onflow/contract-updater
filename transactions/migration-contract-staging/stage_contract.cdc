import "MigrationContractStaging"

/// This transaction is used to stage a contract update for Cadence 1.0 contract migrations.
///
/// Ensure that this transaction is signed by the account that owns the contract to be updated and that the contract
/// has already been deployed to the signing account.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
/// @param contractName: The name of the contract to be updated with the given code
/// @param contractCode: The updated contract code as a hex-encoded String
///
transaction(contractName: String, contractCode: String) {
    let host: &MigrationContractStaging.Host
    
    prepare(signer: AuthAccount) {
        // Configure Host resource if needed
        let hostStoragePath: StoragePath = MigrationContractStaging.deriveHostStoragePath(hostAddress: signer.address)
        if signer.borrow<&MigrationContractStaging.Host>(from: hostStoragePath) == nil {
            signer.save(<-MigrationContractStaging.createHost(), to: hostStoragePath)
        }
        // Assign Host reference
        self.host = signer.borrow<&MigrationContractStaging.Host>(from: hostStoragePath)!
    }

    execute {
        // Call staging contract, storing the contract code that will update during Cadence 1.0 migration
        MigrationContractStaging.stageContract(host: self.host, name: contractName, code: contractCode)
    }

    post {
        MigrationContractStaging.isStaged(address: self.host.address(), name: contractName):
            "Problem while staging update"
    }
}
