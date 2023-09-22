import "ContractUpdater"

access(all) struct ContractUpdateReadable {
    access(all) let address: Address
    access(all) let name: String
    access(all) let code: String

    init(
        address: Address,
        name: String,
        code: String
    ) {
        self.address = address
        self.name = name
        self.code = code
    }
}

/// Returns values of the Updater at the given Address
///
access(all) fun main(address: Address): [[ContractUpdateReadable]]? {
    
    let account = getAuthAccount<auth(Storage) &Account>(address)
     
    if let updater = account.storage.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath) {

        let result: [[ContractUpdateReadable]] = []
        let deployments = updater.getDeployments()

        for stage in deployments {
            let data: [ContractUpdateReadable] = []
            for contractUpdate in stage {
                data.append(
                        ContractUpdateReadable(
                        address: contractUpdate.address,
                        name: contractUpdate.name,
                        code: contractUpdate.stringifyCode()
                    )
                )
            }
            result.append(data)
        }
        
        return result
    }

    return nil

}
