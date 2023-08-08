import "ContractUpdater"

/// Returns values of the Updater at the given Address
///
pub fun main(address: Address): [{Address: String}]? {
    let account = getAuthAccount(address)
     
    if let updater = account.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath) {
        let data: [{Address: String}] = []
        let deployment = updater.getDeployment()

        for contractUpdate in deployment {
            data.append({
                contractUpdate.address: contractUpdate.name
            })
        }
        
        return data
    }

    return nil

}
