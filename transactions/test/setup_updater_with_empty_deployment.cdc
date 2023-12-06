import "StagedContractUpdates"

/// TEST TRANSACTION
/// Should fail on Updater.init() due to empty hosts and deployments arrays
///
transaction {
    prepare(signer: AuthAccount) {
        let updater <- StagedContractUpdates.createNewUpdater(
            blockUpdateBoundary: StagedContractUpdates.blockUpdateBoundary,
            hosts: [],
            deployments: []
        )
        signer.save(<-updater, to: StagedContractUpdates.UpdaterStoragePath)
    }
}
