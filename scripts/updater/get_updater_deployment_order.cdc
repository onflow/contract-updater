import "StagedContractUpdates"

/// Returns values of the Updater at the given Address
///
access(all) fun main(address: Address): [[{Address: String}]]? {
    let account = getAuthAccount<auth(BorrowValue) &Account>(address)
     
    if let updater = account.borrow<&StagedContractUpdates.Updater>(from: StagedContractUpdates.UpdaterStoragePath) {
        let result: [[{Address: String}]] = []
        let deployments = updater.getDeployments()

        for i, stage in deployments {
            let data: [{Address: String}] = []
            for contractUpdate in stage {
                data.append({
                    contractUpdate.address: contractUpdate.name
                })
            }
            result.append(data)
        }
        
        return result
    }

    return nil

}
