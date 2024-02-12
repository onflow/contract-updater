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
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateGetAllStagedContractHostsScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetAllStagedContractHosts)
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateGetAllStagedContractsScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetAllStagedContracts)
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateGetStagedContractCodeScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagedContractCode)
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateGetStagedContractNamesForAddressScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagedContractNamesForAddress)
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateGetStagedContractUpdateScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagedContractUpdate)
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateGetStagingCutoffScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameGetStagingCutoff)
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateIsStagedScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameIsStaged)
	return replaceAddresses(code, migrationContractStagingAddress)
}

func GenerateIsValidatedScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameIsValidated)
	return replaceAddresses(code, migrationContractStagingAddress)
}
