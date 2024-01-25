import "MigrationContractStaging"

/// Returns a mapping of status checks on various conditions affecting contract staging or nil if not staged.
/// A successful status check will look like:
/// {
///     "Updater": "PASSING",
///     "Host": "PASSING",
///     "Staged Update": "PASSING",
///     "Contract Existence": "PASSING"
/// }
/// If a status check fails, the value will be "FAILING:" followed by the reason for failure
///
access(all) fun main(contractAddress: Address, contractName: String): {String: String}? {
    let updaterPath: StoragePath = MigrationContractStaging.deriveUpdaterStoragePath(
            contractAddress: contractAddress, contractName: contractName
        )
    return getAuthAccount(contractAddress).borrow<&MigrationContractStaging.Updater>(from: updaterPath)?.statusCheck()
}
