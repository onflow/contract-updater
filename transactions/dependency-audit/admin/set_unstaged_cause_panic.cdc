import "DependencyAudit"

transaction(shouldPanic: Bool) {
    prepare(signer: auth(BorrowValue) &Account) {
        signer.storage.borrow<&DependencyAudit.Administrator>(from: DependencyAudit.AdministratorStoragePath)?.setPanicOnUnstagedDependencies(shouldPanic: shouldPanic)
        ?? panic("Could not borrow DependencyAudit.Administrator from signer's storage!")
    }
}
