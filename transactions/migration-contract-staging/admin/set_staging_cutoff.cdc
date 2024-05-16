import "MigrationContractStaging"

/// Sets the block height at which contracts can no longer be staged
///
transaction(cutoff: UInt64) {
  
    let admin: &MigrationContractStaging.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        self.admin = signer.storage.borrow<&MigrationContractStaging.Admin>(from: MigrationContractStaging.AdminStoragePath)
            ?? panic("Could not borrow Admin reference")
    }

    execute {
        self.admin.setStagingCutoff(at: cutoff)
    }

    post {
        MigrationContractStaging.getStagingCutoff() == cutoff:
            "Staging cutoff was not set properly"
    }
}
