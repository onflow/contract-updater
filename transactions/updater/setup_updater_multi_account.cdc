import "MetadataViews"

import "StagedContractUpdates"

/// Retrieves Host Capabilities from the contract-hosting accounts and assigns an update deployment in an encapsulating
/// Updater. This demos an advanced case where an update deployment involves a network of dependent contracts across
/// multiple hosting accounts.
///
/// NOTES: deploymentConfig is ordered, and the order is used to determine the order of the contracts in the deployment.
/// Each entry in the array must be exactly one key-value pair, where the key is the address of the associated contract
/// name and code.
/// This transaction also assumes that all contract hosting AuthAccount Capabilities have been published for the signer
/// to claim.
///
transaction(blockHeightBoundary: UInt64?, contractAddresses: [Address], deploymentConfig: [[{Address: {String: String}}]]) {

    prepare(signer: AuthAccount) {
        // Abort if Updater is already configured in signer's account
        if signer.type(at: StagedContractUpdates.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }

        // Claim all Host Capabilities from contract addresses
        let hostCaps: [Capability<&StagedContractUpdates.Host>] = []
        let seenAddresses: [Address] = []
        for address in contractAddresses {
            if seenAddresses.contains(address) {
                continue
            }
            let hostCap: Capability<&StagedContractUpdates.Host> = signer.inbox.claim<&StagedContractUpdates.Host>(
                StagedContractUpdates.inboxHostCapabilityNamePrefix.concat(signer.address.toString()),
                provider: address
            ) ?? panic("No Host Capability found in Inbox for signer at address: ".concat(address.toString()))
            hostCaps.append(hostCap)
            seenAddresses.append(address)
        }
        // Construct deployment from config
        let deployments: [[StagedContractUpdates.ContractUpdate]] = StagedContractUpdates.getDeploymentFromConfig(deploymentConfig)

        if blockHeightBoundary == nil && StagedContractUpdates.blockUpdateBoundary == nil {
            // TODO: THIS IS A PROBLEM - Can't setup Updater without a contract blockHeightBoundary
            panic("Contract update boundary is not yet set, must specify blockHeightBoundary if not coordinating")
        }
        // Construct the updater, save and link public Capability
        let contractUpdater: @StagedContractUpdates.Updater <- StagedContractUpdates.createNewUpdater(
                blockUpdateBoundary: blockHeightBoundary ?? StagedContractUpdates.blockUpdateBoundary!,
                hosts: hostCaps,
                deployments: deployments
            )
        signer.save(
            <-contractUpdater,
            to: StagedContractUpdates.UpdaterStoragePath
        )
        signer.unlink(StagedContractUpdates.UpdaterPublicPath)
        signer.link<&{StagedContractUpdates.UpdaterPublic, MetadataViews.Resolver}>(
            StagedContractUpdates.UpdaterPublicPath,
            target: StagedContractUpdates.UpdaterStoragePath
        )
    }
}
