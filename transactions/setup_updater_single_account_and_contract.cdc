#allowAccountLinking

import "ContractUpdater"

/// Configures and Updater resource, assuming signing account is the account with the contract to update. This demos a
/// simple case where the signer is the deployment account and deployment only includes a single contract.
///
transaction(blockUpdateBoundary: UInt64, contractName: String, code: String) {
    prepare(signer: AuthAccount) {
        if !signer.getCapability<&AuthAccount>(ContractUpdater.UpdaterContractAccountPrivatePath).check() {
            signer.unlink(ContractUpdater.UpdaterContractAccountPrivatePath)
            signer.linkAccount(ContractUpdater.UpdaterContractAccountPrivatePath)
        }
        let accountCap: Capability<&AuthAccount> = signer.getCapability<&AuthAccount>(ContractUpdater.UpdaterContractAccountPrivatePath)
        if signer.type(at: ContractUpdater.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }
        signer.save(
            <- ContractUpdater.createNewUpdater(
                blockUpdateBoundary: blockUpdateBoundary,
                accounts: [accountCap],
                deployments: [[
                    ContractUpdater.ContractUpdate(
                        address: signer.address,
                        name: contractName,
                        code: code
                    )
                ]]
            ),
            to: ContractUpdater.UpdaterStoragePath
        )
        signer.unlink(ContractUpdater.UpdaterPublicPath)
        signer.unlink(ContractUpdater.DelegatedUpdaterPrivatePath)
        signer.link<&ContractUpdater.Updater{ContractUpdater.UpdaterPublic}>(ContractUpdater.UpdaterPublicPath, target: ContractUpdater.UpdaterStoragePath)
        signer.link<&ContractUpdater.Updater{ContractUpdater.DelegatedUpdater, ContractUpdater.UpdaterPublic}>(ContractUpdater.DelegatedUpdaterPrivatePath, target: ContractUpdater.UpdaterStoragePath)
    }
}