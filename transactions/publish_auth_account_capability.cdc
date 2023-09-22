import "ContractUpdater"

/// Publishes an Capability on the signer's Account for the specified recipient
///
transaction(publishFor: Address) {
    
    prepare(signer: auth(IssueAccountCapabilityController, PublishInboxCapability) &Account) {
        let accountCap = signer.capabilities.account.issue<auth(UpdateContract) &Account>()
        
        assert(accountCap.check(), message: "Invalid Account Capability retrieved")
        
        signer.inbox.publish(
            accountCap,
            name: ContractUpdater.inboxAccountCapabilityNamePrefix.concat(publishFor.toString()),
            recipient: publishFor
        )
    }
}