import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Stage Contract Update",
    description: "Stages the provided contract code in the staging contract for Cadence 1.0 contract migrations. Only the contract host can perform this action.",
    language: "en-US",
)

/// This transaction is used to stage a contract update for Cadence 1.0 contract migrations.
///
/// Ensure that this transaction is signed by the account that owns the contract to be updated and that the contract
/// has already been deployed to the signing account.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
/// @param contractName: The name of the contract to be updated with the given code
/// @param contractCode: The updated contract code
///
transaction(contractName: String, contractCode: String) {
    let host: &MigrationContractStaging.Host
    
    prepare(signer: auth(BorrowValue, SaveValue) &Account) {
        // Configure Host resource if needed
        if signer.storage.borrow<&MigrationContractStaging.Host>(from: MigrationContractStaging.HostStoragePath) == nil {
            signer.storage.save(<-MigrationContractStaging.createHost(), to: MigrationContractStaging.HostStoragePath)
        }
        // Assign Host reference
        self.host = signer.storage.borrow<&MigrationContractStaging.Host>(from: MigrationContractStaging.HostStoragePath)!
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
