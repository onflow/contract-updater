import "MetadataViews"

import "StagedContractUpdates"

/// Returns UpdaterInfo view from the Updater at the given address or nil if none is found
///
pub fun main(address: Address): StagedContractUpdates.UpdaterInfo? {
    return getAccount(address).getCapability<&{StagedContractUpdates.UpdaterPublic, MetadataViews.Resolver}>(
            StagedContractUpdates.UpdaterPublicPath
        ).borrow()
        ?.resolveView(Type<StagedContractUpdates.UpdaterInfo>()) as! StagedContractUpdates.UpdaterInfo?
}
