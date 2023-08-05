import "ContractUpdater"

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
pub fun main(address: Address): [ContractUpdateReadable]? {
    let account = getAuthAccount(address)
     
    if let updater = account.borrow<&ContractUpdater.Updater>(from: ContractUpdater.UpdaterStoragePath) {
        let data: [ContractUpdateReadable] = []
        let deployment = updater.getDeployment()

        for contractUpdate in deployment {
            data.append(
                ContractUpdateReadable(
                    address: contractUpdate.address,
                    name: contractUpdate.name,
                    code: contractUpdate.stringifyCode()
                )
            )
        }
        
        return data
    }

    return nil

}
