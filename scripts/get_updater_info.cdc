import "ContractUpdater"

access(all) struct ContractUpdateReadable {
    access(all) let name: String
    access(all) let code: String

    init(
        name: String,
        code: String
    ) {
        self.name = name
        self.code = code
    }
}

/// Returns values of the Updater at the given Address
///
access(all) fun main(address: Address): {Int: {Address: [ContractUpdateReadable]}}? {
    let account = getAuthAccount<auth(Storage) &Account>(address)
     
    if let updater = account.storage.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath) {
        let result: {Int: {Address: [ContractUpdateReadable]}} = {}
        let deployments = updater.getDeployments()

        for i, stage in deployments {
            let data: {Address: [ContractUpdateReadable]} = {}
            for contractUpdate in stage {
                if !data.containsKey(contractUpdate.address) {
                    data.insert(key: contractUpdate.address, [])
                }
                data[contractUpdate.address]!.append(
                    ContractUpdateReadable(
                        name: contractUpdate.name,
                        code: contractUpdate.codeAsCadence()
                    )
                )
            }
            result.insert(key: i, data)
        }
        
        return result
    }

    return nil

}
