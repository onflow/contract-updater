import "DependencyAudit"

transaction(dependenciesAddresses: [Address], dependenciesNames: [String], authorizers: [Address]) {
    prepare(signer: AuthAccount) {
        signer.borrow<&DependencyAudit.Administrator>(from: DependencyAudit.AdministratorStoragePath)?.testCheckDependencies(dependenciesAddresses, dependenciesNames, authorizers)
        ?? panic("Could not borrow DependencyAudit.Administrator from signer's storage!")
    }
}
