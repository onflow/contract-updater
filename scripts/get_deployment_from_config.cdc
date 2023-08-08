import "ContractUpdater"

pub fun main(config: [{Address: {String: String}}]): [ContractUpdater.ContractUpdate] {
    return ContractUpdater.getDeploymentFromConfig(config)
}