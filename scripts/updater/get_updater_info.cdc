import "ViewResolver"

import "StagedContractUpdates"

/// Returns UpdaterInfo view from the Updater at the given address or nil if none is found
///
access(all) fun main(address: Address): StagedContractUpdates.UpdaterInfo? {
    return getAccount(address).capabilities.borrow<&{StagedContractUpdates.UpdaterPublic, ViewResolver.Resolver}>(
            StagedContractUpdates.UpdaterPublicPath
        )?.resolveView(Type<StagedContractUpdates.UpdaterInfo>()) as! StagedContractUpdates.UpdaterInfo?
}
