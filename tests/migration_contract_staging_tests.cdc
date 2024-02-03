import Test
import BlockchainHelpers
import "MigrationContractStaging"

// Contract hosts as defined in flow.json
access(all) let fooAccount = Test.getAccount(0x0000000000000008)
access(all) let aAccount = Test.getAccount(0x0000000000000009)
access(all) let bcAccount = Test.getAccount(0x0000000000000010)

// Content of update contracts as hex strings
access(all) let fooUpdateCode = "61636365737328616c6c2920636f6e747261637420466f6f207b0a2020202061636365737328616c6c292066756e20666f6f28293a20537472696e67207b0a202020202020202072657475726e2022626172220a202020207d0a7d0a"
access(all) let fooUpdateCadence = String.fromUTF8(fooUpdateCode.decodeHex()) ?? panic("Problem decoding fooUpdateCode")
access(all) let aUpdateCode = "61636365737328616c6c2920636f6e747261637420696e746572666163652041207b0a202020200a2020202061636365737328616c6c29207265736f7572636520696e746572666163652049207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e670a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e670a202020207d0a0a2020202061636365737328616c6c29207265736f757263652052203a2049207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e67207b0a20202020202020202020202072657475726e2022666f6f220a20202020202020207d0a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e67207b0a20202020202020202020202072657475726e2022626172220a20202020202020207d0a202020207d0a7d"
access(all) let aUpdateCadence = String.fromUTF8(aUpdateCode.decodeHex()) ?? panic("Problem decoding aUpdateCode")
access(all) let bUpdateCode = "696d706f727420412066726f6d203078303030303030303030303030303030390a0a61636365737328616c6c2920636f6e74726163742042203a2041207b0a202020200a2020202061636365737328616c6c29207265736f757263652052203a20412e49207b0a202020202020202061636365737328616c6c292066756e20666f6f28293a20537472696e67207b0a20202020202020202020202072657475726e2022666f6f220a20202020202020207d0a202020202020202061636365737328616c6c292066756e2062617228293a20537472696e67207b0a20202020202020202020202072657475726e2022626172220a20202020202020207d0a202020207d0a202020200a2020202061636365737328616c6c292066756e206372656174655228293a204052207b0a202020202020202072657475726e203c2d637265617465205228290a202020207d0a7d"
access(all) let bUpdateCadence = String.fromUTF8(bUpdateCode.decodeHex()) ?? panic("Problem decoding bUpdateCode")
access(all) let cUpdateCode = "696d706f727420412066726f6d203078303030303030303030303030303030390a696d706f727420422066726f6d203078303030303030303030303030303031300a0a61636365737328616c6c2920636f6e74726163742043207b0a0a2020202061636365737328616c6c29206c65742053746f72616765506174683a2053746f72616765506174680a2020202061636365737328616c6c29206c6574205075626c6963506174683a205075626c6963506174680a0a2020202061636365737328616c6c29207265736f7572636520696e74657266616365204f757465725075626c6963207b0a202020202020202061636365737328616c6c292066756e20676574466f6f46726f6d2869643a2055496e743634293a20537472696e670a202020202020202061636365737328616c6c292066756e2067657442617246726f6d2869643a2055496e743634293a20537472696e670a202020207d0a0a2020202061636365737328616c6c29207265736f75726365204f75746572203a204f757465725075626c6963207b0a202020202020202061636365737328616c6c29206c657420696e6e65723a20407b55496e7436343a20412e527d0a0a2020202020202020696e69742829207b0a20202020202020202020202073656c662e696e6e6572203c2d207b7d0a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e20676574466f6f46726f6d2869643a2055496e743634293a20537472696e67207b0a20202020202020202020202072657475726e2073656c662e626f72726f775265736f75726365286964293f2e666f6f2829203f3f2070616e696328224e6f207265736f7572636520666f756e64207769746820676976656e20494422290a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e2067657442617246726f6d2869643a2055496e743634293a20537472696e67207b0a20202020202020202020202072657475726e2073656c662e626f72726f775265736f75726365286964293f2e6261722829203f3f2070616e696328224e6f207265736f7572636520666f756e64207769746820676976656e20494422290a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e206164645265736f75726365285f20693a2040412e5229207b0a20202020202020202020202073656c662e696e6e65725b692e757569645d203c2d2120690a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e20626f72726f775265736f75726365285f2069643a2055496e743634293a20267b412e497d3f207b0a20202020202020202020202072657475726e202673656c662e696e6e65725b69645d20617320267b412e497d3f0a20202020202020207d0a0a202020202020202061636365737328616c6c292066756e2072656d6f76655265736f75726365285f2069643a2055496e743634293a2040412e523f207b0a20202020202020202020202072657475726e203c2d2073656c662e696e6e65722e72656d6f7665286b65793a206964290a20202020202020207d0a0a202020202020202064657374726f792829207b0a20202020202020202020202064657374726f792073656c662e696e6e65720a20202020202020207d0a202020207d0a0a20202020696e69742829207b0a202020202020202073656c662e53746f7261676550617468203d202f73746f726167652f4f757465720a202020202020202073656c662e5075626c696350617468203d202f7075626c69632f4f757465725075626c69630a0a202020202020202073656c662e6163636f756e742e736176653c404f757465723e283c2d637265617465204f7574657228292c20746f3a2073656c662e53746f7261676550617468290a202020202020202073656c662e6163636f756e742e6c696e6b3c267b4f757465725075626c69637d3e2873656c662e5075626c6963506174682c207461726765743a2073656c662e53746f7261676550617468290a0a20202020202020206c6574206f75746572203d2073656c662e6163636f756e742e626f72726f773c264f757465723e2866726f6d3a2073656c662e53746f726167655061746829210a20202020202020206f757465722e6164645265736f75726365283c2d20422e637265617465522829290a202020207d0a7d"
access(all) let cUpdateCadence = String.fromUTF8(cUpdateCode.decodeHex()) ?? panic("Problem decoding cUpdateCode")

// Block height different to add to the staging cutoff
access(all) let blockHeightDelta: UInt64 = 10

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
}

access(all) fun testStagedNonExistentContractFails() {
    let alice = Test.createAccount()
    let txResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["A", aUpdateCadence],
        alice
    )
    Test.expect(txResult, Test.beFailed())
    assertIsStaged(contractAddress: alice.address, contractName: "A", invert: true)
}

access(all) fun testStageContractSucceeds() {
    let txResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["Foo", fooUpdateCadence],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())

    assertIsStaged(contractAddress: fooAccount.address, contractName: "Foo", invert: false)

    let fooAccountStagedContractNames = getStagedContractNamesForAddress(fooAccount.address)
    Test.assert(fooAccountStagedContractNames.length == 1, message: "Invalid number of staged contracts on fooAccount")

    let allStagedContractHosts = getAllStagedContractHosts()
    assertAddressArraysEqual([fooAccount.address], allStagedContractHosts)

    let fooStagedContractCode = getStagedContractCode(contractAddress: fooAccount.address, contractName: "Foo")
        ?? panic("Problem retrieving result of getStagedContractCode()")
    Test.assertEqual(fooUpdateCadence, fooStagedContractCode)

    let allStagedCodeForFooAccount = getAllStagedContractCodeForAddress(contractAddress: fooAccount.address)
    assertStagedContractCodeEqual({ "Foo": fooUpdateCadence}, allStagedCodeForFooAccount)

    let events = Test.eventsOfType(Type<MigrationContractStaging.StagingStatusUpdated>())
    Test.assertEqual(1, events.length)

    let evt = events[0] as! MigrationContractStaging.StagingStatusUpdated
    Test.assertEqual(fooAccount.address, evt.address)
    Test.assertEqual("Foo", evt.contract)
    Test.assertEqual("stage", evt.action)
}

access(all) fun testStageMultipleContractsSucceeds() {
    // Demonstrating staging multiple contracts on the same host & out of dependency order
    let cStagingTxResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["C", cUpdateCadence],
        bcAccount
    )
    Test.expect(cStagingTxResult, Test.beSucceeded())
    let bStagingTxResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["B", bUpdateCadence],
        bcAccount
    )
    Test.expect(bStagingTxResult, Test.beSucceeded())
    let aStagingTxResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["A", aUpdateCadence],
        aAccount
    )
    Test.expect(aStagingTxResult, Test.beSucceeded())

    assertIsStaged(contractAddress: aAccount.address, contractName: "A", invert: false)
    assertIsStaged(contractAddress: bcAccount.address, contractName: "B", invert: false)
    assertIsStaged(contractAddress: bcAccount.address, contractName: "C", invert: false)

    let events = Test.eventsOfType(Type<MigrationContractStaging.StagingStatusUpdated>())
    Test.assertEqual(4, events.length)
    let cEvt = events[1] as! MigrationContractStaging.StagingStatusUpdated
    Test.assertEqual(bcAccount.address, cEvt.address)
    Test.assertEqual("C", cEvt.contract)
    Test.assertEqual("stage", cEvt.action)
    let bEvt = events[2] as! MigrationContractStaging.StagingStatusUpdated
    Test.assertEqual(bcAccount.address, cEvt.address)
    Test.assertEqual("B", bEvt.contract)
    Test.assertEqual("stage", bEvt.action)
    let aEvt = events[3] as! MigrationContractStaging.StagingStatusUpdated
    Test.assertEqual(aAccount.address, aEvt.address)
    Test.assertEqual("A", aEvt.contract)
    Test.assertEqual("stage", aEvt.action)

    let aAccountStagedContractNames = getStagedContractNamesForAddress(aAccount.address)
    let bcAccountStagedContractNames = getStagedContractNamesForAddress(bcAccount.address)
    Test.assert(aAccountStagedContractNames.length == 1, message: "Invalid number of staged contracts on aAccount")
    Test.assert(bcAccountStagedContractNames.length == 2, message: "Invalid number of staged contracts on bcAccount")

    let allStagedContractHosts = getAllStagedContractHosts()
    assertAddressArraysEqual([fooAccount.address, aAccount.address, bcAccount.address], allStagedContractHosts)

    let aStagedCode = getStagedContractCode(contractAddress: aAccount.address, contractName: "A")
        ?? panic("Problem retrieving result of getStagedContractCode()")
    let bStagedCode = getStagedContractCode(contractAddress: bcAccount.address, contractName: "B")
        ?? panic("Problem retrieving result of getStagedContractCode()")
    let cStagedCode = getStagedContractCode(contractAddress: bcAccount.address, contractName: "C")
        ?? panic("Problem retrieving result of getStagedContractCode()")
    Test.assertEqual(aUpdateCadence, aStagedCode)
    Test.assertEqual(bUpdateCadence, bStagedCode)
    Test.assertEqual(cUpdateCadence, cStagedCode)

    let allStagedCodeForAAccount = getAllStagedContractCodeForAddress(contractAddress: aAccount.address)
    let allStagedCodeForBCAccount = getAllStagedContractCodeForAddress(contractAddress: bcAccount.address)
    assertStagedContractCodeEqual({ "A": aUpdateCadence }, allStagedCodeForAAccount)
    assertStagedContractCodeEqual({ "B": bUpdateCadence, "C": cUpdateCadence }, allStagedCodeForBCAccount)
}

access(all) fun testReplaceStagedCodeSucceeds() {
    let txResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["Foo", fooUpdateCadence],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())

    let events = Test.eventsOfType(Type<MigrationContractStaging.StagingStatusUpdated>())
    Test.assertEqual(5, events.length)
    let evt = events[4] as! MigrationContractStaging.StagingStatusUpdated
    Test.assertEqual(fooAccount.address, evt.address)
    Test.assertEqual("Foo", evt.contract)
    Test.assertEqual("replace", evt.action)
}

access(all) fun testUnstageContractSucceeds() {
    let txResult = executeTransaction(
        "../transactions/migration-contract-staging/unstage_contract.cdc",
        ["Foo"],
        fooAccount
    )
    Test.expect(txResult, Test.beSucceeded())

    let events = Test.eventsOfType(Type<MigrationContractStaging.StagingStatusUpdated>())
    Test.assertEqual(6, events.length)
    let evt = events[5] as! MigrationContractStaging.StagingStatusUpdated
    Test.assertEqual(fooAccount.address, evt.address)
    Test.assertEqual("Foo", evt.contract)
    Test.assertEqual("unstage", evt.action)

    assertIsStaged(contractAddress: fooAccount.address, contractName: "Foo", invert: true)

    let fooAccountStagedContractNames = getStagedContractNamesForAddress(fooAccount.address)
    Test.assert(fooAccountStagedContractNames.length == 0, message: "Invalid number of staged contracts on fooAccount")

    let allStagedContractHosts = getAllStagedContractHosts()
    assertAddressArraysEqual([aAccount.address, bcAccount.address], allStagedContractHosts)

    let fooStagedContractCode = getStagedContractCode(contractAddress: fooAccount.address, contractName: "Foo")
    Test.assertEqual(nil, fooStagedContractCode)

    let allStagedCodeForFooAccount = getAllStagedContractCodeForAddress(contractAddress: fooAccount.address)
    assertStagedContractCodeEqual({}, allStagedCodeForFooAccount)
}

access(all) fun testSetStagingCutoffSucceeds() {
    let admin = Test.getAccount(0x07)
    let currentHeight = executeScript(
        "../scripts/test/get_current_block_height.cdc",
        []
    ).returnValue as! UInt64? ?? panic("Problem retrieving current block height")
    let expectedCutoff: UInt64 = currentHeight + blockHeightDelta
    let txResult = executeTransaction(
        "../transactions/migration-contract-staging/admin/set_staging_cutoff.cdc",
        [expectedCutoff],
        admin
    )
    Test.expect(txResult, Test.beSucceeded())

    let events = Test.eventsOfType(Type<MigrationContractStaging.StagingCutoffUpdated>())
    Test.assertEqual(1, events.length)
    let evt = events[0] as! MigrationContractStaging.StagingCutoffUpdated
    Test.assertEqual(nil, evt.old)
    Test.assertEqual(expectedCutoff, evt.new!)

    let stagingCutoffResult = executeScript(
        "../scripts/migration-contract-staging/get_staging_cutoff.cdc",
        []
    )
    let stagingCutoff = stagingCutoffResult.returnValue as! UInt64? ?? panic("Problem retrieving staging cutoff value")
    Test.assertEqual(expectedCutoff, stagingCutoff)

    tickTock(advanceBlocks: blockHeightDelta + 1, admin)
}

access(all) fun testStageBeyondCutoffFails() {

    let stageAttemptResult = executeTransaction(
        "../transactions/migration-contract-staging/stage_contract.cdc",
        ["Foo"],
        fooAccount
    )
    Test.expect(stageAttemptResult, Test.beFailed())
}

/* --- Test Helpers --- */

access(all) fun assertIsStaged(contractAddress: Address, contractName: String, invert: Bool) {
    let isStagedResult = executeScript(
        "../scripts/migration-contract-staging/is_staged.cdc",
        [contractAddress, contractName]
    )
    let isStaged = isStagedResult.returnValue as! Bool? ?? panic("Problem retrieving result of isStaged()")
    Test.assertEqual(!invert, isStaged)
}

access(all) fun assertAddressArraysEqual(_ expected: [Address], _ actual: [Address]) {
    Test.assert(expected.length == actual.length, message: "Arrays are of unequal length")
    for address in expected {
        Test.assert(actual.contains(address), message: "Actual array does not contain ".concat(address.toString()))
    }
}

access(all) fun assertStagedContractCodeEqual(_ expected: {String: String}, _ actual: {String: String}) {
    Test.assert(expected.length == actual.length, message: "Staged code mappings are of unequal length")
    expected.forEachKey(fun(contractName: String): Bool {
        Test.assert(
            actual[contractName] == expected[contractName],
            message: "Mismatched code for contract ".concat(contractName)
        )
        return true
    })
}

access(all) fun getStagedContractNamesForAddress(_ address: Address): [String] {
    let stagedContractNamesResult = executeScript(
        "../scripts/migration-contract-staging/get_staged_contract_names_for_address.cdc",
        [address]
    )
    return stagedContractNamesResult.returnValue as! [String]?
        ?? panic("Problem retrieving result of getAllStagedContractNamesForAddress()")
}

access(all) fun getAllStagedContractHosts(): [Address] {
    let allStagedContractHostsResult = executeScript(
        "../scripts/migration-contract-staging/get_all_staged_contract_hosts.cdc",
        []
    )
    return allStagedContractHostsResult.returnValue as! [Address]?
        ?? panic("Problem retrieving result of getAllStagedContractHosts()")
}

access(all) fun getStagedContractCode(contractAddress: Address, contractName: String): String? {
    let stagedContractCodeResult = executeScript(
        "../scripts/migration-contract-staging/get_staged_contract_code.cdc",
        [contractAddress, contractName]
    )
    return stagedContractCodeResult.returnValue as! String?
}

access(all) fun getAllStagedContractCodeForAddress(contractAddress: Address): {String: String} {
    let allStagedContractCodeForAddressResult = executeScript(
        "../scripts/migration-contract-staging/get_all_staged_contract_code_for_address.cdc",
        [contractAddress]
    )
    return allStagedContractCodeForAddressResult.returnValue as! {String: String}?
        ?? panic("Problem retrieving result of getAllStagedContractCodeForAddress()")
}

access(all) fun tickTock(advanceBlocks: UInt64, _ signer: Test.Account) {
    var blocksAdvanced: UInt64 = 0
    while blocksAdvanced < advanceBlocks {
        
        let txResult = executeTransaction("../transactions/test/tick_tock.cdc", [], signer)
        Test.expect(txResult, Test.beSucceeded())

        blocksAdvanced = blocksAdvanced + 1
    }
}