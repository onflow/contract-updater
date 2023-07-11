transaction {
    prepare(signer: AuthAccount) {
        log("Block height incremented to: ".concat(getCurrentBlock().height.toString()))
    }
}