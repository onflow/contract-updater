import "StagedContractUpdates"

pub struct ContractUpdateReadable {
    pub let address: Address
    pub let name: String
    pub let code: String

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
pub fun main(address: Address): [[ContractUpdateReadable]]? {
    
    let account = getAuthAccount(address)
     
    if let updater = account.borrow<&StagedContractUpdates.Updater>(from: StagedContractUpdates.UpdaterStoragePath) {

        let result: [[ContractUpdateReadable]] = []
        let deployments = updater.getDeployments()

        for stage in deployments {
            let data: [ContractUpdateReadable] = []
            for contractUpdate in stage {
                data.append(
                        ContractUpdateReadable(
                        address: contractUpdate.address,
                        name: contractUpdate.name,
                        code: contractUpdate.codeAsCadence()
                    )
                )
            }
            result.append(data)
        }
        
        return result
    }

    return nil

}
