import "MigrationContractStaging"

/// Returns the block height at which contracts can no longer be staged.
///
access(all) fun main(): UInt64? {
    return MigrationContractStaging.getStagingCutoff()
}
