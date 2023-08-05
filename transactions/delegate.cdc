import "ContractUpdater"

transaction {
    
    let delegatee: &ContractUpdater.Delegatee{ContractUpdater.DelegateePublic}
    let updaterCap: Capability<&ContractUpdater.Updater{ContractUpdater.DelegatedUpdater, ContractUpdater.UpdaterPublic}>
    let updaterID: UInt64
    
    prepare(signer: AuthAccount) {
        let delegateeAccount = getAccount(ContractUpdater.getContractAddress())
        self.delegatee = delegateeAccount.getCapability<&ContractUpdater.Delegatee{ContractUpdater.DelegateePublic}>(
                ContractUpdater.DelegateePublicPath
            ).borrow()
            ?? panic("Could not borrow Delegatee reference")
        self.updaterCap = signer.getCapability<&ContractUpdater.Updater{ContractUpdater.DelegatedUpdater, ContractUpdater.UpdaterPublic}>(
                ContractUpdater.DelegatedUpdaterPrivatePath
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