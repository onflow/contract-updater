package templates

import (
	"github.com/onflow/flow-go-sdk"

	"github.com/onflow/contract-updater/lib/go/templates/internal/assets"
)

const (
	filenameGetAllStagedContractCodeForAddress = "scripts/migration-contract-staging/get_all_staged_contract_code_for_address.cdc"
	filenameGetAllStagedContractHosts          = "scripts/migration-contract-staging/get_all_staged_contract_hosts.cdc"
	filenameGetAllStagedContracts              = "scripts/migration-contract-staging/get_all_staged_contracts.cdc"
	filenameGetStagedContractCode              = "scripts/migration-contract-staging/get_staged_contract_code.cdc"
	filenameGetStagedContractNamesForAddress   = "scripts/migration-contract-staging/get_staged_contract_names_for_address.cdc"
	filenameGetStagedContractUpdate            = "scripts/migration-contract-staging/get_staged_contract_update.cdc"
	filenameGetStagingCutoff                   = "scripts/migration-contract-staging/get_staging_cutoff.cdc"
	filenameIsStaged                           = "scripts/migration-contract-staging/is_staged.cdc"
	filenameIsValidated                        = "scripts/migration-contract-staging/is_validated.cdc"
)

func GenerateGetAllStagedContractCodeForAddressScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetAllStagedContractCodeForAddress)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateGetAllStagedContractHostsScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetAllStagedContractHosts)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateGetAllStagedContractsScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetAllStagedContracts)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateGetStagedContractCodeScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagedContractCode)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateGetStagedContractNamesForAddressScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagedContractNamesForAddress)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateGetStagedContractUpdateScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagedContractUpdate)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateGetStagingCutoffScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagingCutoff)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateIsStagedScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameIsStaged)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateIsValidatedScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameIsValidated)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}
