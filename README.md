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
| ------- | ------- |
| Testnet | TBD     |
| Mainnet | TBD     |

### Pre-Requisites

- An existing contract deployed to your target network. For example, if you're staging `A` in address `0x01`, you should
  already have a contract named `A` deployed to `0x01`.
- A Cadence 1.0 compatible contract serving as an update to your existing contract. Extending our example, if you're
  staging `A` in address `0x01`, you should have a contract named `A` that is Cadence 1.0 compatible. See the references
  below for more information on Cadence 1.0 language changes.
- Your contract as a hex string. You can get this by running `./hex-encode.sh <CONTRACT_FILENAME>` - **be sure to
  explicitly state your contract's import addresses!**

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
        if signer.borrow<&MigrationContractStaging.Host>(from: MigrationContractStaging.HostStoragePath) == nil {
            signer.save(<-MigrationContractStaging.createHost(), to: MigrationContractStaging.HostStoragePath)
        }
        // Assign Host reference
        self.host = signer.borrow<&MigrationContractStaging.Host>(from: MigrationContractStaging.HostStoragePath)!
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
this contract's code previously, it will be overwritten by the code you provided in this transaction.

> :warning: NOTE: Staging your contract successfully does not mean that your contract code is correct. Your testing and
> validation processes should include testing your contract code against the Cadence 1.0 interpreter to ensure your
> contract will function as expected.

### Checking Staging Status

You may later want to retrieve your contract's staged code. To do so, you can run the [`get_staged_contract_code.cdc`
script](./scripts/migration-contract-staging/get_staged_contract_code.cdc), passing the address & name of the contract
you're requesting and getting the Cadence code in return. This script can also help you get the staged code for your
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

## `MigrationContractStaging` Contract Details

The basic interface to stage a contract is the same as deploying a contract - name + code. See the
[`stage_contract`](./transactions/migration-contract-staging/stage_contract.cdc) &
[`unstage_contract`](./transactions/migration-contract-staging/unstage_contract.cdc) transactions. Note that calling
`stageContract()` again for the same contract will overwrite any existing staged code for that contract.

```cadence
/// 1 - Create a host and save it in your contract-hosting account at MigrationContractStaging.HostStoragePath
access(all) fun createHost(): @Host
/// 2 - Call stageContract() with the host reference and contract name and contract code you wish to stage.
access(all) fun stageContract(host: &Host, name: String, code: String)
/// Removes the staged contract code from the staging environment.
access(all) fun unstageContract(host: &Host, name: String)
```

To stage a contract, the developer first saves a `Host` resource in their account which they pass as a reference along
with the contract name and code they wish to stage. The `Host` reference simply serves as proof of authority that the
caller has access to the contract-hosting account, which in the simplest case would be the signer of the staging
transaction, though conceivably this could be delegated to some other account via Capability - possibly helpful for some
multisig contract hosts.

```cadence
/// Serves as identification for a caller's address.
access(all) resource Host {
    /// Returns the resource owner's address
    access(all) view fun address(): Address
}
```

Within the `MigrationContractStaging` contract account, code is saved on a contract-basis as a `ContractUpdate` struct
within a `Capsule` resource and stored at a the derived path. The `Capsule` simply serves as a dedicated repository for
staged contract code.

```cadence
/// Represents contract and its corresponding code.
access(all) struct ContractUpdate {
    access(all) let address: Address
    access(all) let name: String
    access(all) var code: String

    /// Validates that the named contract exists at the target address.
    access(all) view fun isValid(): Bool 
    /// Serializes the address and name into a string of the form 0xADDRESS.NAME
    access(all) view fun toString(): String
    /// Returns human-readable string of the Cadence code.
    access(all) view fun codeAsCadence(): String
    /// Replaces the ContractUpdate code with that provided.
    access(contract) fun replaceCode(_ code: String)
}

/// Resource that stores pending contract updates in a ContractUpdate struct.
access(all) resource Capsule {
    /// The address, name and code of the contract that will be updated.
    access(self) let update: ContractUpdate

    /// Returns the staged contract update in the form of a ContractUpdate struct.
    access(all) view fun getContractUpdate(): ContractUpdate
    /// Replaces the staged contract code with the given hex-encoded Cadence code.
    access(contract) fun replaceCode(code: String)
}
```

To support monitoring staging progress across the network, the single `StagingStatusUpdated` event is emitted any time a
contract is staged (`status == "stage"`), staged code is replaced (`status == "replace"`), or a contract is unstaged
(`status == "unstage"`).

```cadence
access(all) event StagingStatusUpdated(
    capsuleUUID: UInt64,
    address: Address,
    codeHash: [UInt8],
    contract: String,
    action: String
)
```
Included in the contact are methods for querying staging status and retrieval of staged code. This enables platforms
like Flowview, Flowdiver, ContractBrowser, etc. to display the staging status of contracts on any given account.

```cadence
/* --- Public Getters --- */
//
/// Returns true if the contract is currently staged.
access(all) fun isStaged(address: Address, name: String): Bool
/// Returns the names of all staged contracts for the given address.
access(all) fun getStagedContractNames(forAddress: Address): [String]
/// Returns the staged contract Cadence code for the given address and name.
access(all) fun getStagedContractCode(address: Address, name: String): String?
/// Returns an array of all staged contract host addresses.
access(all) view fun getAllStagedContractHosts(): [Address]
/// Returns a dictionary of all staged contract code for the given address.
access(all) fun getAllStagedContractCode(forAddress: Address): {String: String}
```

## References

More tooling is slated to support Cadence 1.0 code changes and will be added as it arises. For any real-time help, be
sure to join the [Flow discord](https://discord.com/invite/J6fFnh2xx6) and ask away in the developer channels!

- [Cadence 1.0 contract migration plan](https://forum.flow.com/t/update-on-cadence-1-0-upgrade-plan/5597)
- [Cadence 1.0 language update breakdown](https://forum.flow.com/t/update-on-cadence-1-0/5197)
- [Cadence Language reference](https://cadence-lang.org/)
- [Emerald City's Cadence 1.0 by Example](https://academy.ecdao.org/en/cadence-by-example)