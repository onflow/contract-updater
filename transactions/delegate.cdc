import "ContractUpdater"

transaction {
    let delegatee: &{ContractUpdater.DelegateePublic}
    let updaterCap: Capability<&ContractUpdater.Updater>
    let updaterID: UInt64
    
    prepare(signer: auth(Capabilities) &Account) {
        let delegateeAccount = getAccount(ContractUpdater.getContractDelegateeAddress())
        self.delegatee = delegateeAccount.capabilities.borrow<&{ContractUpdater.DelegateePublic}>(
                ContractUpdater.DelegateePublicPath
            ) ?? panic("Could not borrow Delegatee reference")
        self.updaterCap = signer.capabilities.storage.issue<&ContractUpdater.Updater>(ContractUpdater.UpdaterStoragePath)
        self.updaterID = self.updaterCap.borrow()?.getID() ?? panic("Invalid Updater Capability retrieved from signer!")
    }

    execute {
        self.delegatee.delegate(updaterCap: self.updaterCap)
    }

    post {
        self.delegatee.check(id: self.updaterID) == true: "Updater Capability was not properly delegated"
    }
}