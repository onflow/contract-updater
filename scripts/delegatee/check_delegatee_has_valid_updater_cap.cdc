import "StagedContractUpdates"

access(all) fun main(updaterAddress: Address, delegateeAddress: Address): Bool? {
    let updater = getAuthAccount<auth(BorrowValue) &Account>(updaterAddress).storage.borrow<&StagedContractUpdates.Updater>(
            from: StagedContractUpdates.UpdaterStoragePath
        ) ?? panic("Could not borrow contract updater reference")
    let id = updater.getID()

    let delegatee = getAuthAccount<auth(BorrowValue) &Account>(delegateeAddress).storage.borrow<&StagedContractUpdates.Delegatee>(
            from: StagedContractUpdates.DelegateeStoragePath
        ) ?? panic("Could not borrow contract delegatee reference")
    return delegatee.check(id: id)
}