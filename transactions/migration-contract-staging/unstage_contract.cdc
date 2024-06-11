import "MigrationContractStaging"

#interaction (
    version: "1.1.0",
    title: "Unstage Contract Update",
    description: "Removes the staged contract code from the staging contract. Only the contract host can perform this action.",
    language: "en-US",
)

/// Unstages the given contract from the staging contract. Only the contract host can perform this action.
/// After the transaction, the contract will no longer be staged for Cadence 1.0 migration.
///
/// For more context, see the repo - https://github.com/onflow/contract-updater
///
transaction(contractName: String) {
    let host: &MigrationContractStaging.Host
    
    prepare(signer: auth(BorrowValue) &Account) {
        // Assign Host reference
        self.host = signer.storage.borrow<&MigrationContractStaging.Host>(from: MigrationContractStaging.HostStoragePath)
            ?? panic("Host was not found in storage")
    }

    execute {
        // Call staging contract, storing the contract code that will update during Cadence 1.0 migration
        MigrationContractStaging.unstageContract(host: self.host, name: contractName)
    }

    post {
        !MigrationContractStaging.isStaged(address: self.host.address(), name: contractName):
            "Problem while unstaging update"
    }
}
