#allowAccountLinking

import "StagedContractUpdates"

/// Configures and Updater resource, assuming signing account is the account with the contract to update. This demos an
/// advanced case where an update deployment involves multiple accounts and contracts.
///
/// NOTES: deploymentConfig is ordered, and the order is used to determine the order of the contracts in the deployment.
/// Each entry in the array must be exactly one key-value pair, where the key is the address of the associated contract
/// name and code.
/// This transaction also assumes that all contract hosting AuthAccount Capabilities have been published for the signer
/// to claim.
///
transaction(blockUpdateBoundary: UInt64, contractAddresses: [Address], deploymentConfig: [[{Address: {String: String}}]]) {

    prepare(signer: AuthAccount) {
        // Abort if Updater is already configured in signer's account
        if signer.type(at: StagedContractUpdates.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }

        // Claim all AuthAccount Capabilities.
        let accountCaps: [Capability<&AuthAccount>] = []
        let seenAddresses: [Address] = []
        for address in contractAddresses {
            if seenAddresses.contains(address) {
                continue
            }
            let accountCap = signer.inbox.claim<&AuthAccount>(
                StagedContractUpdates.inboxAccountCapabilityNamePrefix.concat(signer.address.toString()),
                provider: address
            ) ?? panic("No AuthAccount Capability found in Inbox for signer at address: ".concat(address.toString()))
            accountCaps.append(accountCap)
            seenAddresses.append(address)
        }
        // Construct deployment from config
        let deployments = StagedContractUpdates.getDeploymentFromConfig(deploymentConfig)
        
        // Construct the updater, save and link Capabilities
        let contractUpdater: @StagedContractUpdates.Updater <- StagedContractUpdates.createNewUpdater(
                blockUpdateBoundary: blockUpdateBoundary,
                accounts: accountCaps,
                deployments: deployments
            )
        signer.save(
            <-contractUpdater,
            to: StagedContractUpdates.UpdaterStoragePath
        )
        signer.unlink(StagedContractUpdates.UpdaterPublicPath)
        signer.unlink(StagedContractUpdates.DelegatedUpdaterPrivatePath)
        signer.link<&StagedContractUpdates.Updater{StagedContractUpdates.UpdaterPublic}>(StagedContractUpdates.UpdaterPublicPath, target: StagedContractUpdates.UpdaterStoragePath)
        signer.link<&StagedContractUpdates.Updater{StagedContractUpdates.DelegatedUpdater, StagedContractUpdates.UpdaterPublic}>(StagedContractUpdates.DelegatedUpdaterPrivatePath, target: StagedContractUpdates.UpdaterStoragePath)
    }
}