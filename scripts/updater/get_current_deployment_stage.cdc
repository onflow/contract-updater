import "StagedContractUpdates"

/// Retrieves the current deployment stage of the Updater at the given Address or nil if an Updater is not found
///
access(all) fun main(updaterAddress: Address): Int? {
    return getAccount(updaterAddress).getCapability<&{StagedContractUpdates.UpdaterPublic}>(
        StagedContractUpdates.UpdaterPublicPath
    ).borrow()
    ?.getCurrentDeploymentStage()
}
