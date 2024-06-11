import "StagedContractUpdates"

/// TEST TRANSACTION
/// Should fail on Updater.init() due to empty hosts and deployments arrays
///
transaction {
    prepare(signer: auth(SaveValue) &Account) {
        let hosts: [Capability<&StagedContractUpdates.Host>] = []
        let deployments: [[StagedContractUpdates.ContractUpdate]] = []
        let updater <- StagedContractUpdates.createNewUpdater(
            blockUpdateBoundary: StagedContractUpdates.blockUpdateBoundary,
            hosts: hosts,
            deployments: deployments
        )
        signer.storage.save(<-updater, to: StagedContractUpdates.UpdaterStoragePath)
    }
}
