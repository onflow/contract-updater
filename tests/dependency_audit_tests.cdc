import Test
import BlockchainHelpers
import "DependencyAudit"

// NOTE: This is an artifact of the implicit Test API - it's not clear how block height transitions between test cases
access(all) let blockHeightBoundaryDelay: UInt64 = 15

// Contract hosts as defined in flow.json
access(all) let adminAccount = Test.getAccount(0x0000000000000007)
access(all) let fooAccount = Test.getAccount(0x0000000000000008)
access(all) let aAccount = Test.getAccount(0x0000000000000009)
access(all) let bcAccount = Test.getAccount(0x0000000000000010)

// Content of update contracts as hex strings
access(all) let aUpdateCode = "61636365737328616c6c2920636f6e747261637420696e746572666163652041207b0a202020200a2020202061636365737328616c6c29207265736f7572636520696e746572666163652049207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e670a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e670a202020207d0a0a2020202061636365737328616c6c29207265736f757263652052203a2049207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e67207b0a20202020202020202020202072657475726e2022666f6f220a20202020202020207d0a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e67207b0a20202020202020202020202072657475726e2022626172220a20202020202020207d0a202020207d0a7d"
access(all) let aUpdateCadence = String.fromUTF8(aUpdateCode.decodeHex()) ?? panic("Problem decoding aUpdateCode")

access(all) fun setup() {
    var err = Test.deployContract(
        name: "MigrationContractStaging",
        path: "../contracts/MigrationContractStaging.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "Foo",
        path: "../contracts/test/Foo.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "A",
        path: "../contracts/test/A.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "B",
        path: "../contracts/test/B.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "C",
        path: "../contracts/test/C.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())

    let excludedAddresses: [Address] = [
        // exclude the admin account
        0x0000000000000007
    ]
    err = Test.deployContract(
        name: "DependencyAudit",
        path: "../contracts/DependencyAudit.cdc",
        arguments: [excludedAddresses]
    )
    Test.expect(err, Test.beNil())


}


access(all) fun testChekDependenciesWithEmptyList() {
    let addresses: [Address] = []
    let names: [String] = []
    let authorizers: [Address] = []
    let commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/test_check_dependencies.cdc",
        [addresses, names, authorizers],
        adminAccount
    )
    Test.expect(commitResult, Test.beSucceeded())

    let events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
    Test.assertEqual(0, events.length)
}

access(all) fun testChekDependenciesWithExcludedEntries() {
    let addresses: [Address] = [adminAccount.address]
    let names: [String] = ["DependencyAudit"]
    let authorizers: [Address] = []
    let commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/test_check_dependencies.cdc",
        [addresses, names, authorizers],
        adminAccount
    )
    Test.expect(commitResult, Test.beSucceeded())

    let events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
        Test.assertEqual(0, events.length)
}

access(all) fun testChekDependenciesWithUnstagedEntries() {
    let addresses: [Address] = [fooAccount.address]
    let names: [String] = ["Foo"]
    let authorizers: [Address] = []
    let commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/test_check_dependencies.cdc",
        [addresses, names, authorizers],
        adminAccount
    )
    Test.expect(commitResult, Test.beSucceeded())

    let events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
    Test.assertEqual(1, events.length)

    let evt = events[0] as! DependencyAudit.UnstagedDependencies
    Test.assertEqual(1, evt.dependenciesAddresses.length)
    Test.assertEqual(1, evt.dependenciesNames.length)
    Test.assertEqual(fooAccount.address, evt.dependenciesAddresses[0])
    Test.assertEqual("Foo", evt.dependenciesNames[0])
}


access(all) fun testChekDependenciesWithStagedEntries() {
    var events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
    Test.assertEqual(1, events.length)

    let addresses: [Address] = [aAccount.address]
    let names: [String] = ["A"]
    let authorizers: [Address] = []
    var commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/test_check_dependencies.cdc",
        [addresses, names, authorizers],
        adminAccount
    )
    Test.expect(commitResult, Test.beSucceeded())

    events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
    Test.assertEqual(2, events.length)
    let evt = events[1] as! DependencyAudit.UnstagedDependencies
    Test.assertEqual(1, evt.dependenciesAddresses.length)
    Test.assertEqual(1, evt.dependenciesNames.length)
    Test.assertEqual(aAccount.address, evt.dependenciesAddresses[0])
    Test.assertEqual("A", evt.dependenciesNames[0])

    let aStagingTxResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["A", aUpdateCadence],
        aAccount
    )
    Test.expect(aStagingTxResult, Test.beSucceeded())

    events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
        Test.assertEqual(2, events.length)

    commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/test_check_dependencies.cdc",
        [addresses, names, authorizers],
        adminAccount
    )
    Test.expect(commitResult, Test.beSucceeded())

    events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
        Test.assertEqual(2, events.length)
}


access(all) fun testChekDependenciesWithMixedEntries() {
    var events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
    Test.assertEqual(2, events.length)

    let addresses: [Address] = [adminAccount.address, fooAccount.address, aAccount.address, bcAccount.address]
    let names: [String] = ["DependencyAudit", "Foo", "A", "B"]
    let authorizers: [Address] = []
    var commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/test_check_dependencies.cdc",
        [addresses, names, authorizers],
        adminAccount
    )
    Test.expect(commitResult, Test.beSucceeded())

    events = Test.eventsOfType(Type<DependencyAudit.UnstagedDependencies>())
        Test.assertEqual(3, events.length)

    let evt = events[2] as! DependencyAudit.UnstagedDependencies
    Test.assertEqual(2, evt.dependenciesAddresses.length)
    Test.assertEqual(2, evt.dependenciesNames.length)
    Test.assertEqual(fooAccount.address, evt.dependenciesAddresses[0])
    Test.assertEqual("Foo", evt.dependenciesNames[0])
    Test.assertEqual(bcAccount.address, evt.dependenciesAddresses[1])
    Test.assertEqual("B", evt.dependenciesNames[1])
}

access(all) fun testSetPanic() {
    let shouldPanic: Bool = true
    var commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/set_unstaged_cause_panic.cdc",
        [shouldPanic],
        adminAccount
    )
    Test.expect(commitResult, Test.beSucceeded())

    var events = Test.eventsOfType(Type<DependencyAudit.PanicOnUnstagedDependenciesChanged>())
        Test.assertEqual(1, events.length)

    let evt = events[0] as! DependencyAudit.PanicOnUnstagedDependenciesChanged
    Test.assertEqual(true, evt.shouldPanic)
}


access(all) fun testChekDependenciesWithUnstagedEntriesPanics() {
    let addresses: [Address] = [fooAccount.address]
    let names: [String] = ["Foo"]
    let authorizers: [Address] = []
    let commitResult = executeTransaction(
        "../transactions/dependency-audit/admin/test_check_dependencies.cdc",
        [addresses, names, authorizers],
        adminAccount
    )
    Test.expect(commitResult, Test.beFailed())
    // not sure how to test this:
    // Test.expect(commitResult.error!.message, Test.contain("panic: Found unstaged dependencies: A.0x0000000000000008.Foo") )
}
