import "StagedContractUpdates"

pub fun main(updaterAddress: Address, delegateeAddress: Address): Bool? {
    let updater = getAuthAccount(updaterAddress).borrow<&StagedContractUpdates.Updater>(
            from: StagedContractUpdates.UpdaterStoragePath
        ) ?? panic("Could not borrow contract updater reference")
    let id = updater.getID()

    let delegatee = getAuthAccount(delegateeAddress).borrow<&StagedContractUpdates.Delegatee>(
            from: StagedContractUpdates.DelegateeStoragePath
        ) ?? panic("Could not borrow contract delegatee reference")
    return delegatee.check(id: id)
}