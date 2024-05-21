import "MigrationContractStaging"

// This contract is is used by the FVM calling the `checkDependencies` function from a function of the same name and singnature in the FlowServiceAccount contract,
// at the end of every transaction.
// The `dependenciesAddresses` and `dependenciesNames` will be all the dependencies needded to run that transaction.
//
// The `checkDependencies` function will check if any of the dependencies are not staged in the MigrationContractStaging contract.
// If any of the dependencies are not staged, the function will emit an event with the unstaged dependencies, or panic if `panicOnUnstaged` is set to true.
access(all) contract DependencyAudit {

    access(all) let AdministratorStoragePath: StoragePath

    // The system addresses have contracts that will not be stages via the migration contract so we exclude them from the dependency chekcs
    access(self) var excludedAddresses: {Address: Bool}

    access(all) var panicOnUnstaged: Bool

    access(all) event UnstagedDependencies(dependencies: [Dependency])

    access(all) event PanicOnUnstagedDependenciesChanged(shouldPanic: Bool)

    // checkDependencies is called from the FlowServiceAccount contract
    access(contract) fun checkDependencies(_ dependenciesAddresses: [Address], _ dependenciesNames: [String], _ authorizers: [Address]) {
        var unstagedDependencies: [Dependency] = []

        var numDependencies = dependenciesAddresses.length
        var i = 0
        while i < numDependencies {
            let isExcluded = DependencyAudit.excludedAddresses[dependenciesAddresses[i]] ?? false
            if isExcluded {
                i = i + 1
                continue
            }

            let staged = MigrationContractStaging.isStaged(address: dependenciesAddresses[i], name: dependenciesNames[i])
            if !staged {
                unstagedDependencies.append(Dependency(address: dependenciesAddresses[i], name: dependenciesNames[i]))
            }

            i = i + 1
        }

        if unstagedDependencies.length > 0 {
            if DependencyAudit.panicOnUnstaged {
                // If `panicOnUnstaged` is set to true, the transaction will panic if there are any unstaged dependencies
                // the panic message will include the unstaged dependencies
                var unstagedDependenciesString = ""
                var numUnstagedDependencies = unstagedDependencies.length
                var j = 0
                while j < numUnstagedDependencies {
                    if j > 0 {
                        unstagedDependenciesString = unstagedDependenciesString.concat(", ")
                    }
                    unstagedDependenciesString = unstagedDependenciesString.concat(unstagedDependencies[j].toString())

                    j = j + 1
                }

                // the transactions will fail with a message that looks like this: `error: panic: Found unstaged dependencies: A.2ceae959ed1a7e7a.MigrationContractStaging, A.2ceae959ed1a7e7a.DependencyAudit`
                panic("Found unstaged dependencies: ".concat(unstagedDependenciesString))
            } else {
                emit UnstagedDependencies(dependencies: unstagedDependencies)
            }
        }
    }

    // The Administrator resorce can be used to add or remove addresses from the excludedAddresses dictionary
    //
    access(all) resource Administrator {
        // addExcludedAddresses add the addresses to the excludedAddresses dictionary
        access(all) fun addExcludedAddresses(addresses: [Address]) {
            for address in addresses {
                DependencyAudit.excludedAddresses[address] = true
            }
        }

        // removeExcludedAddresses remove the addresses from the excludedAddresses dictionary
        access(all) fun removeExcludedAddresses(addresses: [Address]) {
            for address in addresses {
                DependencyAudit.excludedAddresses.remove(key: address)
            }
        }

        // setPanicOnUnstagedDependencies sets the `panicOnUnstaged` variable to the value of `shouldPanic`
        access(all) fun setPanicOnUnstagedDependencies(shouldPanic: Bool) {
            DependencyAudit.panicOnUnstaged = shouldPanic
            emit PanicOnUnstagedDependenciesChanged(shouldPanic: shouldPanic)
        }

        // testCheckDependencies is used for testing purposes
        // It will call the `checkDependencies` function with the provided dependencies
        // `checkDependencies` is otherwise not callable from the outside
        access(all) fun testCheckDependencies(_ dependenciesAddresses: [Address], _ dependenciesNames: [String], _ authorizers: [Address]) {
            return DependencyAudit.checkDependencies(dependenciesAddresses, dependenciesNames, authorizers)
        }
    }

    access(all) struct Dependency {
        access(all) let address: Address
        access(all) let name: String

        init(address: Address, name: String) {
            self.address = address
            self.name = name
        }

        access(all) fun toString(): String {
            var addressString = self.address.toString()
            // remove 0x prefix
            addressString = addressString.slice(from: 2, upTo: addressString.length)
            return "A.".concat(addressString).concat(".").concat(self.name)
        }
    }

    // The admin resource is saved to the storage so that the admin can be accessed by the service account
    // The `excludedAddresses` will be the addresses with the system contracts.
    init(excludedAddresses: [Address]) {
        self.excludedAddresses = {}
        self.panicOnUnstaged = false

        self.AdministratorStoragePath = /storage/flowDependencyAuditAdmin

        for address in excludedAddresses {
            self.excludedAddresses[address] = true
        }

        let admin <- create Administrator()
        self.account.save(<-admin, to: self.AdministratorStoragePath)
    }
}
