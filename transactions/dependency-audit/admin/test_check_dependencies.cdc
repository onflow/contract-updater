import "DependencyAudit"

transaction(dependenciesAddresses: [Address], dependenciesNames: [String], authorizers: [Address]) {
    prepare(signer: auth(BorrowValue) &Account) {
        signer.storage.borrow<&DependencyAudit.Administrator>(from: DependencyAudit.AdministratorStoragePath)?.testCheckDependencies(dependenciesAddresses, dependenciesNames, authorizers)
        ?? panic("Could not borrow DependencyAudit.Administrator from signer's storage!")
    }
}
