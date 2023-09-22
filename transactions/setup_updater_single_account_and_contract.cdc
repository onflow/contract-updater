import "ContractUpdater"

/// Configures and Updater resource, assuming signing account is the account with the contract to update. This demos a
/// simple case where the signer is the deployment account and deployment only includes a single contract.
///
transaction(blockUpdateBoundary: UInt64, contractName: String, code: String) {
    
    prepare(signer: auth(Capabilities, SaveValue) &Account) {
        // Revert if an Updater is already configured at the expected path in signer's storage
        if signer.storage.type(at: ContractUpdater.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }

        // Create a capability to the signer's account with the ability to update the contract
        let accountCap = signer.capabilities.account.issue<auth(UpdateContract) &Account>()

        // Define deployments from transaction arguments
        let deployments: [[ContractUpdater.ContractUpdate]] = [[
            ContractUpdater.ContractUpdate(
                address: signer.address,
                name: contractName,
                code: code
            )
        ]]
        // Construct a new Updater resource and save it to storage
        let updater <- ContractUpdater.createNewUpdater(
            blockUpdateBoundary: blockUpdateBoundary,
            accounts: [accountCap],
            deployments: deployments
        )
        signer.storage.save(<-updater, to: ContractUpdater.UpdaterStoragePath)

        // Publish the Updater's public interface to the world
        let updaterPublicCap = signer.capabilities.storage.issue<&{ContractUpdater.UpdaterPublic}>(ContractUpdater.UpdaterStoragePath)
        signer.capabilities.publish(updaterPublicCap, at:ContractUpdater.UpdaterPublicPath)
    }
}