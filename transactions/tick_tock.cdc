transaction {
    prepare(signer: AuthAccount) {
        log("Block heigh incremented to: ".concat(getCurrentBlock().height.toString()))
    }
}