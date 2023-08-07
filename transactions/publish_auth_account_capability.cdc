#allowAccountLinking

import "ContractUpdater"

/// Publishes an Capability on the signer's AuthAccount for the specified recipient
///
transaction(publishFor: Address) {
    
    let accountCap: Capability<&AuthAccount>
    
    prepare(signer: AuthAccount) {
        if !signer.getCapability<&AuthAccount>(ContractUpdater.UpdaterContractAccountPrivatePath).check() {
            signer.unlink(ContractUpdater.UpdaterContractAccountPrivatePath)
            self.accountCap = signer.linkAccount(ContractUpdater.UpdaterContractAccountPrivatePath)
                ?? panic("Problem linking AuthAccount Capability")
        } else {
            self.accountCap = signer.getCapability<&AuthAccount>(ContractUpdater.UpdaterContractAccountPrivatePath)
        }
        
        assert(self.accountCap.check(), message: "Invalid AuthAccount Capability retrieved")
        
        signer.inbox.publish(
            self.accountCap,
            name: ContractUpdater.inboxAccountCapabilityNamePrefix.concat(publishFor.toString()),
            recipient: publishFor
        )
    }
}