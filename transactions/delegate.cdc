import "StagedContractUpdates"

transaction {
    
    let delegatee: &StagedContractUpdates.Delegatee{StagedContractUpdates.DelegateePublic}
    let updaterCap: Capability<&StagedContractUpdates.Updater{StagedContractUpdates.DelegatedUpdater, StagedContractUpdates.UpdaterPublic}>
    let updaterID: UInt64
    
    prepare(signer: AuthAccount) {
        let delegateeAccount = getAccount(StagedContractUpdates.getContractDelegateeAddress())
        self.delegatee = delegateeAccount.getCapability<&StagedContractUpdates.Delegatee{StagedContractUpdates.DelegateePublic}>(
                StagedContractUpdates.DelegateePublicPath
            ).borrow()
            ?? panic("Could not borrow Delegatee reference")
        self.updaterCap = signer.getCapability<&StagedContractUpdates.Updater{StagedContractUpdates.DelegatedUpdater, StagedContractUpdates.UpdaterPublic}>(
                StagedContractUpdates.DelegatedUpdaterPrivatePath
            )
        self.updaterID = self.updaterCap.borrow()?.getID() ?? panic("Invalid Updater Capability retrieved from signer!")
    }

    execute {
        self.delegatee.delegate(updaterCap: self.updaterCap)
    }

    post {
        self.delegatee.check(id: self.updaterID) == true: "Updater Capability was not properly delegated"
    }
}