/// Transaction to increment the block height in emulator
///
transaction {
    prepare(signer: &Account) {
        log("Block height incremented to: ".concat(getCurrentBlock().height.toString()))
    }
}