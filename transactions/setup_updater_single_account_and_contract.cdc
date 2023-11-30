#allowAccountLinking

import "StagedContractUpdates"

/// Configures and Updater resource, assuming signing account is the account with the contract to update. This demos a
/// simple case where the signer is the deployment account and deployment only includes a single contract.
///
transaction(blockUpdateBoundary: UInt64, contractName: String, code: String) {
    prepare(signer: AuthAccount) {
        if !signer.getCapability<&AuthAccount>(StagedContractUpdates.UpdaterContractAccountPrivatePath).check() {
            signer.unlink(StagedContractUpdates.UpdaterContractAccountPrivatePath)
            signer.linkAccount(StagedContractUpdates.UpdaterContractAccountPrivatePath)
        }
        let accountCap: Capability<&AuthAccount> = signer.getCapability<&AuthAccount>(StagedContractUpdates.UpdaterContractAccountPrivatePath)
        if signer.type(at: StagedContractUpdates.UpdaterStoragePath) != nil {
            panic("Updater already configured at expected path!")
        }
        signer.save(
            <- StagedContractUpdates.createNewUpdater(
                blockUpdateBoundary: blockUpdateBoundary,
                accounts: [accountCap],
                deployments: [[
                    StagedContractUpdates.ContractUpdate(
                        address: signer.address,
                        name: contractName,
                        code: code
                    )
                ]]
            ),
            to: StagedContractUpdates.UpdaterStoragePath
        )
        signer.unlink(StagedContractUpdates.UpdaterPublicPath)
        signer.unlink(StagedContractUpdates.DelegatedUpdaterPrivatePath)
        signer.link<&StagedContractUpdates.Updater{StagedContractUpdates.UpdaterPublic}>(StagedContractUpdates.UpdaterPublicPath, target: StagedContractUpdates.UpdaterStoragePath)
        signer.link<&StagedContractUpdates.Updater{StagedContractUpdates.DelegatedUpdater, StagedContractUpdates.UpdaterPublic}>(StagedContractUpdates.DelegatedUpdaterPrivatePath, target: StagedContractUpdates.UpdaterStoragePath)
    }
}