import "ContractUpdater"

/// Returns values of the Updater at the given Address or nil if none found
///
pub fun main(address: Address): String? {
    let account = getAuthAccount(address)
     
    if let updater = account.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath) {
        return updater.getContractCode()
    }

    return nil
}
