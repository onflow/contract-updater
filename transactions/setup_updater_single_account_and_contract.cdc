import "ContractUpdater"

/// Configures and Updater resource, assuming signing account is the account with the contract to update. This demos a
/// simple case where the signer is the deployment account and deployment only includes a single contract.
///
// TODO: Remove when CLI param issue fixed
// transaction(blockUpdateBoundary: UInt64, contractName: String, code: String) {
transaction {
    
    prepare(signer: auth(Capabilities, Storage) &Account) {
        // TODO: Remove when CLI param issue fixed
        let blockUpdateBoundary: UInt64 = 10
        let contractName: String = "Foo"
        let code: String = "61636365737328616c6c2920636f6e747261637420466f6f207b0a2020202061636365737328616c6c2920766965772066756e20666f6f28293a20537472696e67207b0a202020202020202072657475726e2022626172220a202020207d0a7d"

        let accountCap = signer.capabilities.account.issue<auth(Contracts) &Account>()
        if signer.storage.type(at: ContractUpdater.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }
        signer.storage.save(
            <- ContractUpdater.createNewUpdater(
                blockUpdateBoundary: blockUpdateBoundary,
                accounts: [accountCap],
                deployments: [[
                    ContractUpdater.ContractUpdate(
                        address: signer.address,
                        name: contractName,
                        code: code.decodeHex()
                    )
                ]]
            ),
            to: ContractUpdater.UpdaterStoragePath
        )
        let updaterPublicCap = signer.capabilities.storage.issue<&{ContractUpdater.UpdaterPublic}>(ContractUpdater.UpdaterStoragePath)
        signer.capabilities.publish(updaterPublicCap, at:ContractUpdater.UpdaterPublicPath)
    }
}