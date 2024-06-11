import "ViewResolver"

import "StagedContractUpdates"

/// Retrieves Host Capabilities from the contract-hosting accounts and assigns an update deployment in an encapsulating
/// Updater. This demos an advanced case where an update deployment involves a network of dependent contracts across
/// multiple hosting accounts.
///
/// NOTES: deploymentConfig is ordered, and the order is used to determine the order of the contracts in the deployment.
/// Each entry in the array must be exactly one key-value pair, where the key is the address of the associated contract
/// name and code.
/// This transaction also assumes that all contract hosting Account Capabilities have been published for the signer to
/// claim.
///
transaction(blockHeightBoundary: UInt64?, contractAddresses: [Address], deploymentConfig: [[{Address: {String: String}}]]) {

    prepare(signer: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, ClaimInboxCapability, PublishCapability) &Account) {
        // Abort if Updater is already configured in signer's account
        if signer.storage.type(at: StagedContractUpdates.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }

        // Claim all Host Capabilities from contract addresses
        let hostCaps: [Capability<auth(UpdateContract) &StagedContractUpdates.Host>] = []
        let seenAddresses: [Address] = []
        for address in contractAddresses {
            if seenAddresses.contains(address) {
                continue
            }
            let hostCap = signer.inbox.claim<auth(UpdateContract) &StagedContractUpdates.Host>(
                StagedContractUpdates.inboxHostCapabilityNamePrefix.concat(signer.address.toString()),
                provider: address
            ) ?? panic("No Host Capability found in Inbox for signer at address: ".concat(address.toString()))
            hostCaps.append(hostCap)
            seenAddresses.append(address)
        }
        // Construct deployment from config
        let deployments: [[StagedContractUpdates.ContractUpdate]] = StagedContractUpdates.getDeploymentFromConfig(deploymentConfig)

        // Construct the updater, save and link public Capability
        let contractUpdater: @StagedContractUpdates.Updater <- StagedContractUpdates.createNewUpdater(
                blockUpdateBoundary: blockHeightBoundary ?? StagedContractUpdates.blockUpdateBoundary,
                hosts: hostCaps,
                deployments: deployments
            )
        signer.storage.save(
            <-contractUpdater,
            to: StagedContractUpdates.UpdaterStoragePath
        )
        let updaterCap = signer.capabilities.storage.issue<&{StagedContractUpdates.UpdaterPublic, ViewResolver.Resolver}>(
            StagedContractUpdates.UpdaterStoragePath
        )
        signer.capabilities.publish(updaterCap, at: StagedContractUpdates.UpdaterPublicPath)
    }
}
