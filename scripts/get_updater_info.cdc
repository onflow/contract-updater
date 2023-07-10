import "ContractUpdater"

/// Returns values of the Updater at the given Address
///
pub fun main(address: Address): {String: AnyStruct}? {
    let account = getAuthAccount(address)
     
    if let updater = account.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath) {
        let data: {String: AnyStruct} = {}
        
        data.insert(key: "block-update-boundary", updater.getBlockUpdateBoundary())
        data.insert(key: "contract-account-address", updater.getContractAccountAddress())
        data.insert(key: "contract-name", updater.getBlockUpdateBoundary())
        data.insert(key: "updated", updater.hasBeenUpdated())
        
        return data
    }

    return nil

}
