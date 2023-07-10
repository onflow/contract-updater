# ContractUpdater

> Enables delayed contract updates to a wrapped account at or beyond a specified block height

## Demo

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
    flow transactions send ./transactions/setup_updater.cdc 10 "Foo" 70756220636f6e747261637420466f6f207b0a202020207075622066756e20666f6f28293a20537472696e67207b0a202020202020202072657475726e2022626172220a202020207d0a7d --signer foo
    ```

1. Simulate block creation, running transactions to iterate over blocks ot the pre-configured block update height:

    ```sh
    sh tick_tock.sh
    ```

1. We can get details from our `Updater` before updating:

    ```sh
    flow scripts execute ./scripts/get_updater_info.cdc 0xe03daebed8ca0615
    ```

    ```sh
    flow scripts execute ./scripts/get_updater_code.cdc 0xe03daebed8ca0615
    ```

1. Lastly, we'll run the updating transaction:

    ```sh
    flow transactions send ./transactions/update.cdc --signer foo
    ```

1. And we can validate the update has taken place by calling `Foo.foo()` again and seeing the return value is now `"bar"`

    ```sh
    flow scripts execute ./scripts/foo.cdc
    ```