import "DependencyAudit"

transaction() {
    prepare(signer: AuthAccount) {
        signer.borrow<&DependencyAudit.Administrator>(from: DependencyAudit.AdministratorStoragePath)?.unsetStartEndBlock()
        ?? panic("Could not borrow DependencyAudit.Administrator from signer's storage!")
    }
}
