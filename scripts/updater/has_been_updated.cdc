import "StagedContractUpdates"

/// Retrieves the update completion status of the Updater at the given Address or nil if an Updater is not found
///
access(all) fun main(updaterAddress: Address): Bool? {
    return getAccount(updaterAddress).capabilities.borrow<&{StagedContractUpdates.UpdaterPublic}>(
        StagedContractUpdates.UpdaterPublicPath
    )?.hasBeenUpdated()
}
