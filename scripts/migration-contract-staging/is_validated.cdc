import "MigrationContractStaging"

#interaction (
    version: "1.0.0",
    title: "Is Contract Validated Query",
    description: "Returns whether a contract is staged and validated. Nil is returned if the contract is not staged.",
    language: "en-US",
)

/// Returns whether a contract update has been validated, returning nil if it isn't staged
///
access(all) fun main(address: Address, name: String): Bool? {
    return MigrationContractStaging.isValidated(address: address, name: name)
}
