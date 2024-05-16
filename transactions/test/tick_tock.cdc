/// TEST TRANSACTION
/// Used to mock block advancement in test suite
///
transaction {
    prepare(signer: &Account) {
        log("Block height incremented to: ".concat(getCurrentBlock().height.toString()))
    }
}
