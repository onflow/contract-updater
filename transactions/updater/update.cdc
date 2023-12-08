#allowAccountLinking
import "StagedContractUpdates"

/// Executes the currently staged update in the signer's Updater resource
///
transaction {
    prepare(signer: AuthAccount) {
        signer.borrow<&StagedContractUpdates.Updater>(from: StagedContractUpdates.UpdaterStoragePath)
            ?.update()
            ?? panic("Could not borrow Updater from signer's storage!")
    }
}
