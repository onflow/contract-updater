import "MigrationContractStaging"

/// Commits the results of offchain emulated migration
///
transaction(startTimestamp: UFix64, failedContracts: [String]) {
  
    let admin: &MigrationContractStaging.Admin

    prepare(signer: AuthAccount) {
        self.admin = signer.borrow<&MigrationContractStaging.Admin>(from: MigrationContractStaging.AdminStoragePath)
            ?? panic("Could not borrow Admin reference")
    }

    execute {
        self.admin.commitMigrationResults(start: startTimestamp, failed: failedContracts)
    }

    post {
        MigrationContractStaging.lastEmulatedMigrationResults!.failedContracts == failedContracts &&
        MigrationContractStaging.lastEmulatedMigrationResults!.start == startTimestamp:
            "Problem committing migration results"
    }
}
