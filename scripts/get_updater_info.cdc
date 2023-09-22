import "ContractUpdater"

pub struct ContractUpdateReadable {
    pub let name: String
    pub let code: String

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
pub fun main(address: Address): {Int: {Address: [ContractUpdateReadable]}}? {
    let account = getAuthAccount(address)
     
    if let updater = account.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath) {
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
