# ContractUpdater

> Enables delayed contract updates to a wrapped account at or beyond a specified block height

## Simple Case Demo

For this run through, we'll focus on the simple case where a single contract is deployed to a single account that can sign the setup & delegation transactions. This is enough to get the basic concepts involved in this setup, but know that more advanced deployments are possible enabling a developer to define multiple accounts and deployment orders so they can account for owned dependency contracts.

1. Start emulator

    ```sh
    flow emulator
    ```

1. Setup emulator environment

    ```sh
    sh setup.sh
    ```

1. We can see that the `Foo` has been deployed, and call its only contract method `foo()`, getting back `"foo"`

    ```sh
    flow scripts execute ./scripts/foo.cdc
    ```

1. Configure `ContractUpdater.Updater`, passing the block height, contract name, and contract code in hex form (see [`get_code_hex.py`](./src/get_code_hex.py) for simple script hexifying contract code):

    ```sh
    flow transactions send ./transactions/setup_updater_single_account_and_contract.cdc 10 "Foo" 70756220636f6e747261637420466f6f207b0a202020207075622066756e20666f6f28293a20537472696e67207b0a202020202020202072657475726e2022626172220a202020207d0a7d --signer foo
    ```

1. Simulate block creation, running transactions to iterate over blocks to the pre-configured block update height:

    ```sh
    sh tick_tock.sh
    ```

1. We can get details from our `Updater` before updating:

    ```sh
    flow scripts execute ./scripts/get_updater_info.cdc 0xe03daebed8ca0615
    ```

    ```sh
    flow scripts execute ./scripts/get_updater_deployment.cdc 0xe03daebed8ca0615
    ```

1. Next, we'll delegate the `Updater` Capability as `DelegatedUpdater` to the `Delegatee` stored in the `ContractUpdater`'s account.

    ```sh
    flow transactions send ./transactions/delegate.cdc --signer foo
    ```

1. Lastly, we'll run the updating transaction as the `Delegatee`:

    ```sh
    flow transactions send ./transactions/execute_delegated_updates.cdc
    ```

1. And we can validate the update has taken place by calling `Foo.foo()` again and seeing the return value is now `"bar"`

    ```sh
    flow scripts execute ./scripts/foo.cdc
    ```

## TODO

- [ ] Implement Delegatee scripts & txns

## Questions/Thoughts

- Devs can order their own deployment, but what if there exist dependencies they don't own that haven't been updated when the `Delegatee` attempts to update their contracts? Will their updates fail since their dependencies aren't yet updated for SC?
    - Does this mean we'll need to account for the chain-wide dependency graph and conduct updates in order of the global dependency tree? Or would we just tell devs to avoid use of this contract if they have unowned/non-standard dependencies?
    - If we plan on supporting global updates with dependency graph resolution, what does the Updater/Delegatee interface need to look like?
        - We could configure the Delegatee such that it takes some DAG and executes the updates according to the given DAG, but we're not guaranteed that all contracts on MN will delegate their updates and thus may not be accessible for the Delegatee to update.