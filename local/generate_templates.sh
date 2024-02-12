#!/bin/bash

flow flix generate ./transactions/migration-contract-staging/stage_contract.cdc --save ./flix/transactions/stage_contract.json
flow flix generate ./transactions/migration-contract-staging/unstage_contract.cdc --save ./flix/transactions/unstage_contract.json
flow flix generate ./scripts/migration-contract-staging/get_all_staged_contract_code_for_address.cdc --save ./flix/scripts/get_all_staged_contract_code_for_address.json
flow flix generate ./scripts/migration-contract-staging/get_all_staged_contract_hosts.cdc --save ./flix/scripts/get_all_staged_contract_hosts.json
flow flix generate ./scripts/migration-contract-staging/get_all_staged_contracts.cdc --save ./flix/scripts/get_all_staged_contracts.json
flow flix generate ./scripts/migration-contract-staging/get_staged_contract_code.cdc --save ./flix/scripts/get_staged_contract_code.json
flow flix generate ./scripts/migration-contract-staging/get_staged_contract_names_for_address.cdc --save ./flix/scripts/get_staged_contract_names_for_address.json
flow flix generate ./scripts/migration-contract-staging/get_staged_contract_update.cdc --save ./flix/scripts/get_staged_contract_update.json
flow flix generate ./scripts/migration-contract-staging/get_staging_cutoff.cdc --save ./flix/scripts/get_staging_cutoff.json
flow flix generate ./scripts/migration-contract-staging/is_staged.cdc --save ./flix/scripts/is_staged.json
flow flix generate ./scripts/migration-contract-staging/is_validated.cdc --save ./flix/scripts/is_validated.json