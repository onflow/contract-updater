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

    access(all) event BlockBoundariesChanged(start: UInt64?, end: UInt64?)

    // checkDependencies is called from the FlowServiceAccount contract
    access(account) fun checkDependencies(_ dependenciesAddresses: [Address], _ dependenciesNames: [String], _ authorizers: [Address]) {
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
            self.maybePanicOnUnstagedDependencies(unstagedDependencies)

            emit UnstagedDependencies(dependencies: unstagedDependencies)
        }
    }

    access(self) fun maybePanicOnUnstagedDependencies(_ unstagedDependencies: [Dependency]) {
        // If `panicOnUnstaged` is set to false, the function will return without panicking
        // Then check if we should panic randomly
        if !DependencyAudit.panicOnUnstaged || !self.shouldPanicRandomly() {
            return
        }

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
        panic("This transaction is using dependencies not staged for Crescendo upgrade coming soon! Learn more: https://bit.ly/FLOWCRESCENDO. Dependencies not staged: ".concat(unstagedDependenciesString))
    }

    // shouldPanicRandomly is used to randomly panic on unstaged dependencies
    // The probability of panicking is based on the current block height and the start and end block heights
    // If the start block height is greater than or equal to the end block height, the function will return true
    // The function will always return true if the current block is more than the end block height
    // The function will always return false if the current block is less than the start block height
    // The function will return true if a random number between the start and end block heights is less than the current block height
    // This means the probability of panicking increases linearly as the current block height approaches the end block height
    access(self) fun shouldPanicRandomly(): Bool {
        // get start block height or true
        // get end block height or true
        // get current block height
        // get random number between start and end
        // if random number is less than current block return true
        // else return false

        let maybeBoundaries = self.getBoundaries()
        if maybeBoundaries == nil {
            // if settings are invalid use default behaviour: panic true
            return true
        }
        let boundaries = maybeBoundaries!

        let startBlock: UInt64 = boundaries.start
        let endBlock: UInt64 = boundaries.end
        let currentBlock: UInt64 = getCurrentBlock().height

        if startBlock >= endBlock {
            // this should never happen becuse we validate the boundaries when setting them
            // if settings are invalid use default behaviour: panic true
            return true
        }

        let dif = endBlock - startBlock
        var rnd = revertibleRandom() % dif
        rnd = rnd + startBlock

        // fail if the random number is less than the current block
        return rnd < currentBlock
    }

    access(all) struct Boundaries {
        access(all) let start: UInt64
        access(all) let end: UInt64

        init(start: UInt64, end: UInt64) {
            self.start = start
            self.end = end
        }
    }

    access(all) fun getBoundaries(): Boundaries? {
        return self.account.copy<Boundaries>(from: /storage/flowDependencyAuditBoundaries)
    }

    access(all) fun getCurrentFailureProbability(): UFix64 {
        if !DependencyAudit.panicOnUnstaged {
            return 0.0 as UFix64
        }

        let maybeBoundaries = self.getBoundaries()
        if maybeBoundaries == nil {
            return 1.0 as UFix64
        }

        let boundaries = maybeBoundaries!

        let startBlock: UInt64 = boundaries.start
        let endBlock: UInt64 = boundaries.end
        let currentBlock: UInt64 = getCurrentBlock().height

        if startBlock >= endBlock {
            return 1.0 as UFix64
        }
        if currentBlock >= endBlock {
            return 1.0 as UFix64
        }
        if currentBlock < startBlock {
            return 0.0 as UFix64
        }

        let dif = endBlock - startBlock
        let currentDif = currentBlock - startBlock

        return UFix64(currentDif) / UFix64(dif)
    }

    access(self) fun setBoundaries(boundaries: Boundaries) {
        self.account.load<Boundaries>(from: /storage/flowDependencyAuditBoundaries)
        self.account.save(boundaries, to: /storage/flowDependencyAuditBoundaries)
    }

    access(self) fun unsetBoundaries() {
        self.account.load<Boundaries>(from: /storage/flowDependencyAuditBoundaries)
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

        // setStartEndBlock sets the start and end block heights for the `shouldPanicRandomly` function
        access(all) fun setStartEndBlock(start: UInt64, end: UInt64) {
            pre {
                start < end: "Start block height must be less than end block height"
            }

            let boundaries = Boundaries(start: start, end: end)
            DependencyAudit.setBoundaries(boundaries: boundaries)
            emit BlockBoundariesChanged(start: start, end: end)
        }

        // unsetStartEndBlock unsets the start and end block heights for the `shouldPanicRandomly` function
        access(all) fun unsetStartEndBlock() {
            DependencyAudit.unsetBoundaries()
            emit BlockBoundariesChanged(start: nil, end: nil)
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
