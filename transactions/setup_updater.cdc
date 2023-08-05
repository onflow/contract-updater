#allowAccountLinking

import "ContractUpdater"

/// Configures and Updater resource, assuming signing account is the account with the contract to update
///
/// @param blockUpdateBoundary: The block height at which the contract can be updated
/// @param contractName: The name of the contract to update
/// @param code: The code of the contract to update as a hex string
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
                deployment: [
                    ContractUpdater.ContractUpdate(
                        address: signer.address,
                        name: contractName,
                        code: code.decodeHex()
                    )
                ]
            ),
            to: ContractUpdater.UpdaterStoragePath
        )
        signer.unlink(ContractUpdater.UpdaterPublicPath)
        signer.unlink(ContractUpdater.DelegatedUpdaterPrivatePath)
        signer.link<&ContractUpdater.Updater{ContractUpdater.UpdaterPublic}>(ContractUpdater.UpdaterPublicPath, target: ContractUpdater.UpdaterStoragePath)
        signer.link<&ContractUpdater.Updater{ContractUpdater.DelegatedUpdater, ContractUpdater.UpdaterPublic}>(ContractUpdater.DelegatedUpdaterPrivatePath, target: ContractUpdater.UpdaterStoragePath)
    }
}