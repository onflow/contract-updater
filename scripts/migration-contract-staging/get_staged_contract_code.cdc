import "MigrationContractStaging"

/// Returns the code as it is staged or nil if it not currently staged.
///
access(all) fun main(contractAddress: Address, contractName: String): String? {
    let updaterPath: StoragePath = MigrationContractStaging.deriveUpdaterStoragePath(
            contractAddress: contractAddress, contractName: contractName
        )
    return getAuthAccount(contractAddress).borrow<&MigrationContractStaging.Updater>(from: updaterPath)
        ?.getContractUpdate()
        ?.codeAsCadence()
}
