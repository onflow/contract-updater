import Test
import BlockchainHelpers

// NOTE: This is an artifact of the implicit Test API - it's not clear how block height transitions between test cases
access(all) let blockHeightBoundaryDelay: UInt64 = 15

// Contract hosts as defined in flow.json
access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let fooAccount = Test.getAccount(0x0000000000000008)
access(all) let aAccount = Test.getAccount(0x0000000000000009)
access(all) let bcAccount = Test.getAccount(0x0000000000000010)

// Account that will host the Updater for contracts A, B, and C
access(all) let abcUpdater = Test.createAccount()

// Content of update contracts as hex strings
access(all) let fooUpdateCode = "61636365737328616c6c2920636f6e747261637420466f6f207b0a2020202061636365737328616c6c292066756e20666f6f28293a20537472696e67207b0a202020202020202072657475726e2022626172220a202020207d0a7d0a"
access(all) let aUpdateCode = "61636365737328616c6c2920636f6e747261637420696e746572666163652041207b0a202020200a2020202061636365737328616c6c29207265736f7572636520696e746572666163652049207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e670a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e670a202020207d0a0a2020202061636365737328616c6c29207265736f757263652052203a2049207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e67207b0a20202020202020202020202072657475726e2022666f6f220a20202020202020207d0a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e67207b0a20202020202020202020202072657475726e2022626172220a20202020202020207d0a202020207d0a7d"
access(all) let bUpdateCode = "696d706f727420412066726f6d203078303030303030303030303030303030390a0a61636365737328616c6c2920636f6e74726163742042203a2041207b0a202020200a2020202061636365737328616c6c29207265736f757263652052203a20412e49207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e67207b0a20202020202020202020202072657475726e2022666f6f220a20202020202020207d0a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e67207b0a20202020202020202020202072657475726e2022626172220a20202020202020207d0a202020207d0a202020200a2020202061636365737328616c6c292066756e206372656174655228293a204052207b0a202020202020202072657475726e203c2d637265617465205228290a202020207d0a7d"
access(all) let cUpdateCode = "696d706f727420412066726f6d203078303030303030303030303030303030390a696d706f727420422066726f6d203078303030303030303030303030303031300a0a61636365737328616c6c2920636f6e74726163742043207b0a0a2020202061636365737328616c6c29206c65742053746f72616765506174683a2053746f72616765506174680a2020202061636365737328616c6c29206c6574205075626c6963506174683a205075626c6963506174680a0a2020202061636365737328616c6c29207265736f7572636520696e74657266616365204f757465725075626c6963207b0a202020202020202061636365737328616c6c292066756e20676574466f6f46726f6d2869643a2055496e743634293a20537472696e670a202020202020202061636365737328616c6c292066756e2067657442617246726f6d2869643a2055496e743634293a20537472696e670a202020207d0a0a2020202061636365737328616c6c29207265736f75726365204f75746572203a204f757465725075626c6963207b0a202020202020202061636365737328616c6c29206c657420696e6e65723a20407b55496e7436343a20412e527d0a0a2020202020202020696e69742829207b0a20202020202020202020202073656c662e696e6e6572203c2d207b7d0a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e20676574466f6f46726f6d2869643a2055496e743634293a20537472696e67207b0a20202020202020202020202072657475726e2073656c662e626f72726f775265736f75726365286964293f2e666f6f2829203f3f2070616e696328224e6f207265736f7572636520666f756e64207769746820676976656e20494422290a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e2067657442617246726f6d2869643a2055496e743634293a20537472696e67207b0a20202020202020202020202072657475726e2073656c662e626f72726f775265736f75726365286964293f2e6261722829203f3f2070616e696328224e6f207265736f7572636520666f756e64207769746820676976656e20494422290a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e206164645265736f75726365285f20693a2040412e5229207b0a20202020202020202020202073656c662e696e6e65725b692e757569645d203c2d2120690a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e20626f72726f775265736f75726365285f2069643a2055496e743634293a20267b412e497d3f207b0a20202020202020202020202072657475726e202673656c662e696e6e65725b69645d20617320267b412e497d3f0a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e2072656d6f76655265736f75726365285f2069643a2055496e743634293a2040412e523f207b0a20202020202020202020202072657475726e203c2d2073656c662e696e6e65722e72656d6f7665286b65793a206964290a20202020202020207d0a0a202020202020202064657374726f792829207b0a20202020202020202020202064657374726f792073656c662e696e6e65720a20202020202020207d0a202020207d0a0a20202020696e69742829207b0a202020202020202073656c662e53746f7261676550617468203d202f73746f726167652f4f757465720a202020202020202073656c662e5075626c696350617468203d202f7075626c69632f4f757465725075626c69630a0a202020202020202073656c662e6163636f756e742e736176653c404f757465723e283c2d637265617465204f7574657228292c20746f3a2073656c662e53746f7261676550617468290a202020202020202073656c662e6163636f756e742e6c696e6b3c267b4f757465725075626c69637d3e2873656c662e5075626c6963506174682c207461726765743a2073656c662e53746f7261676550617468290a0a20202020202020206c6574206f75746572203d2073656c662e6163636f756e742e626f72726f773c264f757465723e2866726f6d3a2073656c662e53746f726167655061746829210a20202020202020206f757465722e6164645265736f75726365283c2d20422e637265617465522829290a202020207d0a7d"

access(all) fun setup() {
    var err = Test.deployContract(
        name: "StagedContractUpdates",
        path: "../contracts/StagedContractUpdates.cdc",
        arguments: [getCurrentBlockHeight() + blockHeightBoundaryDelay]
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
}

access(all) fun testEmptyDeploymentUpdaterInitFails() {
    let alice = Test.createAccount()
    let txResult = executeTransaction(
        "../transactions/test/setup_updater_with_empty_deployment.cdc",
        [],
        alice
    )
    Test.expect(txResult, Test.beFailed())
}

access(all) fun testSetupMultiContractMultiAccountUpdater() {
    let contractAddresses: [Address] = [aAccount.address, bcAccount.address]
    let stage0: [{Address: {String: String}}] = [
        {
            aAccount.address: {
                "A": aUpdateCode
            }
        }
    ]
    let stage1: [{Address: {String: String}}] = [
            {
                bcAccount.address: {
                    "B": bUpdateCode
                }
            }
        ]
    let stage2: [{Address: {String: String}}] = [
            {
                bcAccount.address: {
                    "C": cUpdateCode
                }
            }
        ]

    let deploymentConfig: [[{Address: {String: String}}]] = [stage0, stage1, stage2]

    let aHostTxResult = executeTransaction(
        "../transactions/host/publish_host_capability.cdc",
        [abcUpdater.address],
        aAccount
    )
    Test.expect(aHostTxResult, Test.beSucceeded())

    let bcHostTxResult = executeTransaction(
        "../transactions/host/publish_host_capability.cdc",
        [abcUpdater.address],
        bcAccount
    )
    Test.expect(bcHostTxResult, Test.beSucceeded())

    let setupUpdaterTxResult = executeTransaction(
        "../transactions/updater/setup_updater_multi_account.cdc",
        [nil, contractAddresses, deploymentConfig],
        abcUpdater
    )

    // Confirm UpdaterCreated event was properly emitted
    // TODO: Uncomment once bug is fixed allowing contract import
    // var events = Test.eventsOfType(Type<StagedContractUpdates.UpdaterCreated>())
    // Test.assertEqual(0, events.length)

    // Validate the current deployment stage is 0
    let currentStage = executeScript("../scripts/get_current_deployment_stage.cdc", [abcUpdater.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, currentStage)

    // Check Updater has valid Host Capabilities
    let invalidHosts = executeScript(
            "../scripts/get_invalid_hosts.cdc",
            [abcUpdater.address]
        ).returnValue as! [Address]? ?? panic("Updater was not found at given address")
    Test.assert(invalidHosts.length == 0, message: "Invalid hosts found")
}

access(all) fun testUpdaterDelegationSucceeds() {
    // Validate the current deployment stage is still 0
    var currentStage = executeScript("../scripts/get_current_deployment_stage.cdc", [abcUpdater.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, currentStage)

    // Delegate ABC updater to contract's delegatee
    let txResult = executeTransaction(
            "../transactions/updater/delegate.cdc",
            [],
            abcUpdater
        )
    Test.expect(txResult, Test.beSucceeded())

    // Ensure valid Updater Capability received by Delegatee
    let validCapReceived = executeScript(
            "../scripts/check_delegatee_has_valid_updater_cap.cdc",
            [abcUpdater.address, admin.address]
        ).returnValue as! Bool? ?? panic("Updater was not found at given address")
    Test.assertEqual(true, validCapReceived)
}

access(all) fun testDelegatedUpdateSucceeds() {
    // Validate the current deployment stage is still 0
    var currentStage = executeScript("../scripts/get_current_deployment_stage.cdc", [abcUpdater.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, currentStage)

    jumpToUpdateBoundary(forUpdater: abcUpdater.address)
    
    // Execute first update stage as Delegatee
    var updateTxResult = executeTransaction(
        "../transactions/delegatee/execute_all_delegated_updates.cdc",
        [],
        admin
    )
    Test.expect(updateTxResult, Test.beSucceeded())

    // Validate stage incremented
    currentStage = executeScript("../scripts/get_current_deployment_stage.cdc", [abcUpdater.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(1, currentStage)

    // Continue through remaining stages (should total 3)
    updateTxResult = executeTransaction(
        "../transactions/delegatee/execute_all_delegated_updates.cdc",
        [],
        admin
    )
    Test.expect(updateTxResult, Test.beSucceeded())

    // Ensure update is not yet complete before final stage
    var updateComplete = executeScript(
            "../scripts/has_been_updated.cdc",
            [abcUpdater.address]
        ).returnValue as! Bool? ?? panic("Updater was not found at given address")
    Test.assertEqual(false, updateComplete)

    currentStage = executeScript("../scripts/get_current_deployment_stage.cdc", [abcUpdater.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(2, currentStage)

        updateTxResult = executeTransaction(
        "../transactions/delegatee/execute_all_delegated_updates.cdc",
        [],
        admin
    )
    Test.expect(updateTxResult, Test.beSucceeded())

    currentStage = executeScript("../scripts/get_current_deployment_stage.cdc", [abcUpdater.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(3, currentStage)
    
    // Validate that Updater has completed all stages
    updateComplete = executeScript(
            "../scripts/has_been_updated.cdc",
            [abcUpdater.address]
        ).returnValue as! Bool? ?? panic("Problem validating Updater delegation success")
    Test.assertEqual(true, updateComplete)

    // Confirm UpdaterUpdated event was properly emitted
    // TODO: Uncomment once bug is fixed allowing contract import
    // events = Test.eventsOfType(Type<StagedContractUpdates.UpdaterUpdated>())
    // Test.assertEqual(3, events.length)

    // Validate the Delegatee has removed the Updater Capability after completion
    let updaterCapRemoved = executeScript(
            "../scripts/check_delegatee_has_valid_updater_cap.cdc",
            [abcUpdater.address, admin.address]
        ).returnValue as! Bool?
    Test.assertEqual(nil, updaterCapRemoved)
}

access(all) fun testSetupSingleContractSingleHostSelfUpdate() {

    let expectedPreUpdateResult: String = "foo"
    
    // Validate the pre-update value of Foo.foo()
    let actualPreUpdateResult = executeScript("../scripts/test/foo.cdc", []).returnValue as! String?
        ?? panic("Problem retrieving result of Foo.foo()")
    Test.assertEqual(expectedPreUpdateResult, actualPreUpdateResult)

    // Configure Updater resource in Foo contract account
    let txResult = executeTransaction(
        "../transactions/updater/setup_updater_single_account_and_contract.cdc",
        [getCurrentBlockHeight() + blockHeightBoundaryDelay, "Foo", fooUpdateCode],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())
    
    // Confirm UpdaterCreated event was properly emitted
    // TODO: Uncomment once bug is fixed allowing contract import
    // var events = Test.eventsOfType(Type<StagedContractUpdates.UpdaterCreated>())
    // Test.assertEqual(2, events.length)

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
        "../transactions/updater/update.cdc",
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
    jumpToUpdateBoundary(forUpdater: fooAccount.address)

    // Validate the current deployment stage is still 0
    let stagePrior = executeScript("../scripts/get_current_deployment_stage.cdc", [fooAccount.address]).returnValue as! Int?
        ?? panic("Updater was not found at given address")
    Test.assertEqual(0, stagePrior)

    // Execute update as Foo contract account
    let txResult = executeTransaction(
        "../transactions/updater/update.cdc",
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
    // Test.assertEqual(4, events.length)

    // Validate the post-update value of Foo.foo()
    let actualPostUpdateResult = executeScript("../scripts/test/foo.cdc", []).returnValue as! String?
        ?? panic("Problem retrieving result of Foo.foo()")
    Test.assertEqual(expectedPostUpdateResult, actualPostUpdateResult)
}

access(all) fun testDelegationOfCompletedUpdaterFails() {
    let txResult = executeTransaction(
        "../transactions/updater/delegate.cdc",
        [],
        fooAccount
    )
    Test.expect(txResult, Test.beFailed())
}

access(all) fun testCoordinatorSetBlockUpdateBoundaryFails() {
    let txResult = executeTransaction(
        "../transactions/coordinator/set_block_update_boundary.cdc",
        [1],
        admin
    )
    Test.expect(txResult, Test.beFailed())
}

access(all) fun testCoordinatorSetBlockUpdateBoundarySucceeds() {
    let txResult = executeTransaction(
        "../transactions/coordinator/set_block_update_boundary.cdc",
        [getCurrentBlockHeight() + blockHeightBoundaryDelay],
        admin
    )
    Test.expect(txResult, Test.beSucceeded())

    // TODO: Uncomment once bug is fixed allowing contract import
    // events = Test.eventsOfType(Type<StagedContractUpdates.ContractBlockUpdateBoundaryUpdated>())
    // Test.assertEqual(1, events.length)
}

/* --- TEST HELPERS --- */

access(all) fun jumpToUpdateBoundary(forUpdater: Address) {
    // Identify current block height in test environment
    let currentHeight = getCurrentBlockHeight()
    // Identify number of blocks to advance
    let updateBoundary = executeScript(
            "../scripts/get_block_update_boundary_from_updater.cdc",
            [forUpdater]
        ).returnValue as! UInt64?
        ?? panic("Problem retrieving updater height boundary")
    // Return if no advancement needed
    if updateBoundary <= currentHeight {
        return
    }
    // Otherwise jump to update boundary
    tickTock(advanceBlocks: updateBoundary - currentHeight, admin)
}

access(all) fun tickTock(advanceBlocks: UInt64, _ signer: Test.Account) {
    var blocksAdvanced: UInt64 = 0
    while blocksAdvanced < advanceBlocks {
        
        let txResult = executeTransaction("../transactions/test/tick_tock.cdc", [], signer)
        Test.expect(txResult, Test.beSucceeded())

        blocksAdvanced = blocksAdvanced + 1
    }
}
