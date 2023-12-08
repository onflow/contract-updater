/// TEST TRANSACTION
/// Used to mock block advancement in test suite
///
transaction {
    prepare(signer: AuthAccount) {
        log("Block height incremented to: ".concat(getCurrentBlock().height.toString()))
    }
}
