import "StagedContractUpdates"

access(all) fun main(config: [[{Address: {String: String}}]]): [[StagedContractUpdates.ContractUpdate]] {
    return StagedContractUpdates.getDeploymentFromConfig(config)
}