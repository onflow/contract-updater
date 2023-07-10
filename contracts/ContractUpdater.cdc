pub contract ContractUpdater {

    pub let UpdaterStoragePath: StoragePath
    pub let UpdaterPrivatePath: PrivatePath
    pub let UpdaterPublicPath: PublicPath
    pub let UpdaterContractAccountPrivatePath: PrivatePath

    pub event UpdaterUpdated(updaterUUID: UInt64, blockUpdateBoundary: UInt64, contractAccountAddress: Address, contractName: String, updated: Bool)

    pub resource interface UpdaterPublic {
        pub fun getBlockUpdateBoundary(): UInt64
        pub fun getContractAccountAddress(): Address
        pub fun getContractName(): String
        pub fun getContractCode(): String
        pub fun getContractCodeAsBytes(): [UInt8]
        pub fun hasBeenUpdated(): Bool
    }

    pub resource Updater : UpdaterPublic {
        access(self) let blockUpdateBoundary: UInt64
        access(self) let contractAccount: Capability<&AuthAccount>
        access(self) let contractName: String
        access(self) let code: [UInt8]
        access(self) var updated: Bool
        
        init(blockUpdateBoundary: UInt64, contractAccount: Capability<&AuthAccount>, contractName: String, code: [UInt8]) {
            pre {
                contractAccount.check(): "Invalid AuthAccount Capability!"
            }
            self.blockUpdateBoundary = blockUpdateBoundary
            self.contractAccount = contractAccount
            self.contractName = contractName
            self.code = code
            self.updated = false
        }

        pub fun update() {
            pre {
                self.updated == false: "Updater has already been updated!"
                self.blockUpdateBoundary <= getCurrentBlock().height: "Not yet at block height threshold!"
            }
            self.borrowAccount().contracts.update__experimental(name: self.getContractName(), code: self.getContractCodeAsBytes())
            self.updated = true
            emit UpdaterUpdated(
                updaterUUID: self.uuid,
                blockUpdateBoundary: self.blockUpdateBoundary,
                contractAccountAddress: self.contractAccount.address,
                contractName: self.contractName,
                updated: self.updated
            )
        }

        pub fun getBlockUpdateBoundary(): UInt64 {
            return self.blockUpdateBoundary
        }

        pub fun getContractAccountAddress(): Address {
            return self.contractAccount.address
        }

        pub fun getContractName(): String {
            return self.contractName
        }

        pub fun getContractCode(): String {
            return String.fromUTF8(self.code) ?? panic("Problem stringifying code!")
        }

        pub fun getContractCodeAsBytes(): [UInt8] {
            return self.code
        }

        pub fun hasBeenUpdated(): Bool {
            return self.updated
        }

        access(self) fun borrowAccount(): &AuthAccount {
            return self.contractAccount.borrow() ?? panic("Could not borrow contract account from stored Capability!")
        }
    }

    pub fun createNewUpdater(blockUpdateBoundary: UInt64, contractAccount: Capability<&AuthAccount>, contractName: String, code: [UInt8]): @Updater {
        let updater <- create Updater(blockUpdateBoundary: blockUpdateBoundary, contractAccount: contractAccount, contractName: contractName, code: code)
        emit UpdaterUpdated(
            updaterUUID: updater.uuid,
            blockUpdateBoundary: blockUpdateBoundary,
            contractAccountAddress: contractAccount.address,
            contractName: contractName,
            updated: false
        )
        return <- updater
    }

    init() {
        self.UpdaterStoragePath = /storage/ContractUpdater
        self.UpdaterPrivatePath = /private/ContractUpdater
        self.UpdaterPublicPath = /public/ContractUpdaterPublic
        self.UpdaterContractAccountPrivatePath = /private/UpdaterContractAccount
    }
}