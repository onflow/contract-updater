#allowAccountLinking

import "StagedContractUpdates"

/// Publishes an Capability on the signer's AuthAccount for the specified recipient
///
transaction(publishFor: Address) {
    
    let accountCap: Capability<&AuthAccount>
    
    prepare(signer: AuthAccount) {
        if !signer.getCapability<&AuthAccount>(StagedContractUpdates.UpdaterContractAccountPrivatePath).check() {
            signer.unlink(StagedContractUpdates.UpdaterContractAccountPrivatePath)
            self.accountCap = signer.linkAccount(StagedContractUpdates.UpdaterContractAccountPrivatePath)
                ?? panic("Problem linking AuthAccount Capability")
        } else {
            self.accountCap = signer.getCapability<&AuthAccount>(StagedContractUpdates.UpdaterContractAccountPrivatePath)
        }
        
        assert(self.accountCap.check(), message: "Invalid AuthAccount Capability retrieved")
        
        signer.inbox.publish(
            self.accountCap,
            name: StagedContractUpdates.inboxAccountCapabilityNamePrefix.concat(publishFor.toString()),
            recipient: publishFor
        )
    }
}