import "MigrationContractStaging"

#interaction (
    version: "1.0.0",
    title: "Get Staging Cutoff Query",
    description: "Returns the block height at which contracts can no longer be staged or nil if it is not yet set.",
    language: "en-US",
)

/// Returns the block height at which contracts can no longer be staged.
///
access(all) fun main(): UInt64? {
    return MigrationContractStaging.getStagingCutoff()
}
