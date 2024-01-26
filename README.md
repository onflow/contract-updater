# Onchain Contract Update Mechanisms

![Tests](https://github.com/onflow/contract-updater/actions/workflows/ci.yml/badge.svg)
[![codecov](https://codecov.io/gh/onflow/contract-updater/graph/badge.svg?token=TAIKIA95FU)](https://codecov.io/gh/onflow/contract-updater)

This repo contains contracts enabling onchain staging of contract updates, providing mechanisms to store code,
delegate update capabilities, and execute staged updates.

## Overview

> :information_source: This document proceeds with an emphasis on the `MigrationContractStaging` contract, which will be
> used for the upcoming Cadence 1.0 network migration. Any contracts currently on Mainnet **WILL** need to be updated
> via state migration on the Cadence 1.0 milestone. This means you **MUST** stage your contract updates before the
> milestone for your contract to continue functioning. Keep reading to understand how to stage your contract update.

The `MigrationContractStaging` contract provides a mechanism for staging contract updates onchain in preparation for
Cadence 1.0. Once you have refactored your existing contracts to be Cadence 1.0 compatible, you will need to stage your
code in this contract for network state migrations to take effect and your contract to be updated with the Height
Coordinated Upgrade.

### `MigrationContractStaging` Deployments

> :information_source: The `MigrationContractStaging` contract is not yet deployed. Its deployment address will be added
> here once it has been deployed.

| Network | Address |
|---|---|
| Testnet | TBD |
| Mainnet | TBD |

### Pre-Requisites

- An existing contract deployed to your target network. For example, if you're staging `A` in address `0x01`, you should
  already have a contract named `A` deployed to `0x01`.
- A Cadence 1.0 compatible contract serving as an update to your existing contract. Extending our example, if you're
  staging `A` in address `0x01`, you should have a contract named `A` that is Cadence 1.0 compatible. See the references
  below for more information on Cadence 1.0 language changes.
- Your contract as a hex string.
  - Included in this repo is a Python util to hex-encode your contract which outputs your contract's code as a hex
    string. With Python installed, run:
    ```sh
    python3 ./src/get_code_hex.py <PATH_TO_YOUR_CONTRACT>
    ```

### Staging Your Contract Update

Armed with your pre-requisites, you're ready to stage your contract update. Simply run the [`stage_contract.cdc`
transaction](./transactions/migration-contract-staging/stage_contract.cdc), passing your contract's name and hex string
as arguments and signing as the contract host account.

```sh
flow transactions send ./transactions/migration-contract-staging/stage_contract.cdc \
    <CONTRACT_NAME> <CONTRACT_HEX_CODE> \
    --signer <YOUR_SIGNER_ALIAS> \
    --network <TARGET_NETWORK>
```

This will execute the following transaction:

```cadence
import "MigrationContractStaging"

transaction(contractName: String, contractCode: String) {
    let host: &MigrationContractStaging.Host
    
    prepare(signer: AuthAccount) {
        // Configure Host resource if needed
        let hostStoragePath: StoragePath = MigrationContractStaging.deriveHostStoragePath(hostAddress: signer.address)
        if signer.borrow<&MigrationContractStaging.Host>(from: hostStoragePath) == nil {
            signer.save(<-MigrationContractStaging.createHost(), to: hostStoragePath)
        }
        // Assign Host reference
        self.host = signer.borrow<&MigrationContractStaging.Host>(from: hostStoragePath)!
    }

    execute {
        // Call staging contract, storing the contract code that will update during Cadence 1.0 migration
        // If code is already staged for the given contract, it will be overwritten.
        MigrationContractStaging.stageContract(host: self.host, name: contractName, code: contractCode)
    }

    post {
        MigrationContractStaging.isStaged(address: self.host.address(), name: contractName):
            "Problem while staging update"
    }
}
```

At the end of this transaction, your contract will be staged in the `MigrationContractStaging` account. If you staged
this contract's code previously, it will be overwritted by the code you provided in this transaction.

> :warning: NOTE: Staging your contract successfully does not mean that your contract code is correct. Your testing and
> validation processes should include testing your contract code against the Cadence 1.0 interpreter to ensure your
> contract will function as expected.

### Checking Staging Status

You may want to validate that your contract has been staged correctly. To do so, you can run the
[`get_staged_contract_code.cdc` script](./scripts/migration-contract-staging/get_staged_contract_code.cdc), passing the
address & name of the contract you're requesting. This script can also help you get the staged code for your
dependencies if the project owner has staged their code.

```sh
flow scripts execute ./scripts/migration-contract-staging/get_staged_contract_code.cdc \
    <CONTRACT_ADDRESS> <CONTRACT_NAME> \
    --network <TARGET_NETWORK>
```

Which runs the script:

```cadence
import "MigrationContractStaging"

/// Returns the code as it is staged or nil if it not currently staged.
///
access(all) fun main(contractAddress: Address, contractName: String): String? {
    return MigrationContractStaging.getStagedContractCode(address: contractAddress, name: contractName)
}
```

## References

More tooling is slated to support Cadence 1.0 code changes and will be added as it arises. For any real-time help, be
sure to join the [Flow discord](https://discord.com/invite/J6fFnh2xx6) and ask away in the developer channels!

- [Cadence 1.0 contract migration plan](https://forum.flow.com/t/update-on-cadence-1-0-upgrade-plan/5597)
- [Cadence 1.0 language update breakdown](https://forum.flow.com/t/update-on-cadence-1-0/5197)
- [Cadence Language reference](https://cadence-lang.org/)
- [Emerald City's Cadence 1.0 by Example](https://academy.ecdao.org/en/cadence-by-example)