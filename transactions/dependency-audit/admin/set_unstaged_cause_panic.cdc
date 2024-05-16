import "DependencyAudit"

transaction(shouldPanic: Bool) {
    prepare(signer: AuthAccount) {
        signer.borrow<&DependencyAudit.Administrator>(from: DependencyAudit.AdministratorStoragePath)?.setPanicOnUnstagedDependencies(shouldPanic: shouldPanic)
        ?? panic("Could not borrow DependencyAudit.Administrator from signer's storage!")
    }
}
