import "MetadataViews"

import "StagedContractUpdates"

/// Returns addresses of Hosts with either invalid Host or encapsulate Account Capabilities from the Updater at the
/// given address or nil if none is found
///
access(all) fun main(updaterAddress: Address): [Address]? {
    return getAccount(updaterAddress).capabilities.borrow<&{StagedContractUpdates.UpdaterPublic}>(
            StagedContractUpdates.UpdaterPublicPath
        )?.getInvalidHosts()
}
