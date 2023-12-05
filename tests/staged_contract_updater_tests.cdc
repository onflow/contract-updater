import Test
import BlockchainHelpers

access(all) let admin: Test.Account = Test.getAccount(0x0000000000000007)
access(all) let fooAccount: Test.Account = Test.getAccount(0x0000000000000008)

// Foo_update.cdc as hex string
access(all) let fooUpdateCode: String = "70756220636f6e747261637420466f6f207b0a202020207075622066756e20666f6f28293a20537472696e67207b0a202020202020202072657475726e2022626172220a202020207d0a7d0a"
access(all) let blockHeightBoundaryDelay: UInt64 = 10

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

access(all) fun testSetupSingleContractSingleHostSelfUpdate() {

    let expectedPreUpdateResult: String = "foo"
    
    // Validate the pre-update value of Foo.foo()
    let actualPreUpdateResult = executeScript("../scripts/foo.cdc", []).returnValue as! String?
        ?? panic("Problem retrieving result of Foo.foo()")
    Test.assertEqual(expectedPreUpdateResult, actualPreUpdateResult)

    // Configure Updater resource in Foo contract account
    let blockUpdateBoundary: UInt64 = getCurrentBlock().height + blockHeightBoundaryDelay
    let txResult = executeTransaction(
        "../transactions/setup_updater_single_account_and_contract.cdc",
        [blockUpdateBoundary, "Foo", fooUpdateCode],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())
    
    // Confirm UpdaterCreated event was properly emitted
    // TODO: Uncomment once bug is fixed allowing contract import
    // var events = Test.eventsOfType(Type<StagedContractUpdates.UpdaterCreated>())
    // Test.assertEqual(1, events.length)

    // Validate the current deployment stage is 0
    let currentStage = executeScript("../scripts/get_current_deployment_stage.cdc", [fooAccount.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, currentStage)
}

access(all) fun testExecuteUpdateFailsBeforeBoundary() {

    // Validate the current deployment stage is still 0
    let stagePrior = executeScript("../scripts/get_current_deployment_stage.cdc", [fooAccount.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, stagePrior)

    // Execute update as Foo contract account
    let txResult = executeTransaction(
        "../transactions/update.cdc",
        [],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())

    // Validate the current deployment stage is still 0
    let stagePost = executeScript("../scripts/get_current_deployment_stage.cdc", [fooAccount.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, stagePost)
}

access(all) fun testExecuteUpdateSucceedsAfterBoundary() {

    let expectedPostUpdateResult: String = "bar"

    // Mock block advancement
    tickTock(advanceBlocks: blockHeightBoundaryDelay, fooAccount)

    // Validate the current deployment stage is still 0
    let stagePrior = executeScript("../scripts/get_current_deployment_stage.cdc", [fooAccount.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, stagePrior)

    // Execute update as Foo contract account
    let txResult = executeTransaction(
        "../transactions/update.cdc",
        [],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())

    // Validate the current deployment stage has advanced
    let stagePost = executeScript("../scripts/get_current_deployment_stage.cdc", [fooAccount.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(1, stagePost)

    // Validate the Updater.hasBeenUpdated() returns true
    let hasBeenUpdated = executeScript("../scripts/has_been_updated.cdc", [fooAccount.address]).returnValue as! Bool?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(true, hasBeenUpdated)
    
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

access(all) fun tickTock(advanceBlocks: UInt64, _ signer: Test.Account) {
    var blocksAdvanced: UInt64 = 0
    while blocksAdvanced < advanceBlocks {
        
        let txResult = executeTransaction("../transactions/tick_tock.cdc", [], signer)
        Test.expect(txResult, Test.beSucceeded())

        blocksAdvanced = blocksAdvanced + 1
    }
}
