import "ContractUpdater"

access(all) fun main(updaterAddress: Address, delegateeAddress: Address): Bool? {
    let updater = getAuthAccount(updaterAddress).borrow<&ContractUpdater.Updater>(
            from: ContractUpdater.UpdaterStoragePath
        ) ?? panic("Could not borrow contract updater reference")
    let id = updater.getID()

    let delegatee = getAuthAccount(delegateeAddress).borrow<&ContractUpdater.Delegatee>(
            from: ContractUpdater.DelegateeStoragePath
        ) ?? panic("Could not borrow contract delegatee reference")
    return delegatee.check(id: id)
}