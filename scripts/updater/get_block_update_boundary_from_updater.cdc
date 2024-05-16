import "StagedContractUpdates"

/// Retrieves the block height update boundary from the Updater at the given Address or nil if an Updater is not found
///
access(all) fun main(updaterAddress: Address): UInt64? {
    return getAccount(updaterAddress).getCapability<&{StagedContractUpdates.UpdaterPublic}>(
        StagedContractUpdates.UpdaterPublicPath
    ).borrow()
    ?.getBlockUpdateBoundary()
}
