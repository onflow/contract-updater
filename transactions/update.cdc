#allowAccountLinking
import "ContractUpdater"

/// Executes the update of the stored contract code in the signer's Updater resource
///
transaction {
    prepare(signer: AuthAccount) {
        signer.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath)
            ?.update()
            ?? panic("Could not borrow Updater from signer's storage!")
    }
}