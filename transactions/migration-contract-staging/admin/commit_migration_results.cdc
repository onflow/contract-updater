import "MigrationContractStaging"

/// Commits the results of offchain emulated migration
///
transaction(snapshotTimestamp: UFix64, failedContracts: [String]) {
  
    let admin: &MigrationContractStaging.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        self.admin = signer.storage.borrow<&MigrationContractStaging.Admin>(from: MigrationContractStaging.AdminStoragePath)
            ?? panic("Could not borrow Admin reference")
    }

    execute {
        self.admin.commitMigrationResults(snapshot: snapshotTimestamp, failed: failedContracts)
    }

    post {
        MigrationContractStaging.lastEmulatedMigrationResult!.failedContracts == failedContracts &&
        MigrationContractStaging.lastEmulatedMigrationResult!.snapshot == snapshotTimestamp:
            "Problem committing migration results"
    }
}
