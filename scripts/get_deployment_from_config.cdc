import "ContractUpdater"

access(all) fun main(config: [[{Address: {String: String}}]]): [[ContractUpdater.ContractUpdate]] {
    return ContractUpdater.getDeploymentFromConfig(config)
}