import Test
import BlockchainHelpers

access(all) let admin: Test.Account = Test.getAccount(0x0000000000000007)
access(all) let fooAccount: Test.Account = Test.getAccount(0x0000000000000008)

// Foo_update.cdc as hex string
access(all) let fooUpdateCode: String = "70756220636f6e747261637420466f6f207b0a202020207075622066756e20666f6f28293a20537472696e67207b0a202020202020202072657475726e2022626172220a202020207d0a7d0a"

access(all) fun setup() {
    var err = Test.deployContract(
        name: "StagedContractUpdates",
        path: "../contracts/StagedContractUpdates.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "Foo",
        path: "../contracts/Foo.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
}

access(all) fun testTickTock() {

    var blocksAdvanced = 0
    let advanceBlocks = 3
    while blocksAdvanced < advanceBlocks {
        
        let txResult = executeTransaction("../transactions/tick_tock.cdc", [], fooAccount)

        blocksAdvanced = blocksAdvanced + 1
    }
}

access(all) fun testSingleContractSingleHostSelfUpdate() {

    let expectedPreUpdateResult: String = "foo"
    let expectedPostUpdateResult: String = "bar"
    
    // Validate the pre-update value of Foo.foo()
    let actualPreUpdateResult = executeScript("../scripts/foo.cdc", []).returnValue as! String?
        ?? panic("Problem retrieving result of Foo.foo()")
    Test.assertEqual(expectedPreUpdateResult, actualPreUpdateResult)

    // Configure Updater resource in Foo contract account
    let blockUpdateBoundary: UInt64 = getCurrentBlock().height + 3
    var txResult = executeTransaction(
        "../transactions/setup_updater_single_account_and_contract.cdc",
        [blockUpdateBoundary, "Foo", fooUpdateCode],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())
    
    // Confirm UpdaterCreated event was properly emitted
    // TODO: Uncomment once bug is fixed allowing contract import
    // var events = Test.eventsOfType(Type<StagedContractUpdates.UpdaterCreated>())
    // Test.assertEqual(1, events.length)

    // Mock block advancement
    tickTock(advanceBlocks: 3, fooAccount)

    // Execute update as Foo contract account
    txResult = executeTransaction(
        "../transactions/update.cdc",
        [],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())
    
    // Confirm UpdaterUpdated event was properly emitted
    // TODO: Uncomment once bug is fixed allowing contract import
    // events = Test.eventsOfType(Type<StagedContractUpdates.UpdaterUpdated>())
    // Test.assertEqual(1, events.length)

    // Validate the post-update value of Foo.foo()
    let actualPostUpdateResult = executeScript("../scripts/foo.cdc", []).returnValue as! String?
        ?? panic("Problem retrieving result of Foo.foo()")
    Test.assertEqual(expectedPostUpdateResult, actualPostUpdateResult)
}



/* --- TEST HELPERS --- */

access(all) fun tickTock(advanceBlocks: Int, _ signer: Test.Account) {
    var blocksAdvanced = 0
    while blocksAdvanced < advanceBlocks {
        
        let txResult = executeTransaction("../transactions/tick_tock.cdc", [], signer)
        Test.expect(txResult, Test.beSucceeded())

        blocksAdvanced = blocksAdvanced + 1
    }
}
