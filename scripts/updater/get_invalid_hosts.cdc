import "MetadataViews"

import "StagedContractUpdates"

/// Returns addresses of Hosts with either invalid Host or encapsulate AuthAccount Capabilities from the Updater at the
/// given address or nil if none is found
///
pub fun main(updaterAddress: Address): [Address]? {
    return getAccount(updaterAddress).getCapability<&{StagedContractUpdates.UpdaterPublic}>(
            StagedContractUpdates.UpdaterPublicPath
        ).borrow()
        ?.getInvalidHosts()
}
