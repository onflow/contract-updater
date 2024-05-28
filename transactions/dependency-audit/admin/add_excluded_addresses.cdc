import "DependencyAudit"

transaction(addresses: [Address]) {
    prepare(signer: auth(BorrowValue) &Account) {
        signer.storage.borrow<&DependencyAudit.Administrator>(from: DependencyAudit.AdministratorStoragePath)?.addExcludedAddresses(addresses: addresses)
        ?? panic("Could not borrow DependencyAudit.Administrator from signer's storage!")
    }
}
