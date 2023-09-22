import "ContractUpdater"

/// Configures and Updater resource, assuming signing account is the account with the contract to update. This demos an
/// advanced case where an update deployment involves multiple accounts and contracts.
///
/// NOTES: deploymentConfig is ordered, and the order is used to determine the order of the contracts in the deployment.
/// Each entry in the array must be exactly one key-value pair, where the key is the address of the associated contract
/// name and code.
/// This transaction also assumes that all contract hosting Account Capabilities have been published for the signer
/// to claim.
///
transaction(blockUpdateBoundary: UInt64, contractAddresses: [Address], deploymentConfig: [[{Address: {String: String}}]]) {

    prepare(signer: auth(ClaimInboxCapability, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
        // Abort if Updater is already configured in signer's account
        if signer.storage.type(at: ContractUpdater.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }

        // Claim all Account Capabilities.
        let accountCaps: [Capability<auth(UpdateContract) &Account>] = []
        let seenAddresses: [Address] = []
        for address in contractAddresses {
            if seenAddresses.contains(address) {
                continue
            }
            let accountCap = signer.inbox.claim<auth(UpdateContract) &Account>(
                ContractUpdater.inboxAccountCapabilityNamePrefix.concat(signer.address.toString()),
                provider: address
            ) ?? panic("No Account Capability found in Inbox for signer at address: ".concat(address.toString()))
            accountCaps.append(accountCap)
            seenAddresses.append(address)
        }
        // Construct deployment from config
        let deployments: [[ContractUpdater.ContractUpdate]] = ContractUpdater.getDeploymentFromConfig(deploymentConfig)
        
        // Construct the updater, save and link Capabilities
        let contractUpdater: @ContractUpdater.Updater <- ContractUpdater.createNewUpdater(
                blockUpdateBoundary: blockUpdateBoundary,
                accounts: accountCaps,
                deployments: deployments
            )
        signer.storage.save(
            <-contractUpdater,
            to: ContractUpdater.UpdaterStoragePath
        )
        let updaterPublicCap = signer.capabilities.storage.issue<&{ContractUpdater.UpdaterPublic}>(ContractUpdater.UpdaterStoragePath)
        signer.capabilities.publish(updaterPublicCap, at:ContractUpdater.UpdaterPublicPath)
    }
}