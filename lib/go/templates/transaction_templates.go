package templates

import (
	"github.com/onflow/flow-go-sdk"

	_ "github.com/kevinburke/go-bindata"

	"github.com/onflow/contract-updater/lib/go/templates/internal/assets"
)

const (
	filenameStageContract          = "transactions/migration-contract-staging/stage_contract.cdc"
	filenameUnstageContract        = "transactions/migration-contract-staging/unstage_contract.cdc"
	filenameCommitMigrationResults = "transactions/migration-contract-staging/admin/commit_migration_results.cdc"
	filenameSetStagingCutoff       = "transactions/migration-contract-staging/admin/set_staging_cutoff.cdc"
)

func GenerateStageContractScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameStageContract)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateUnstageContractScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameUnstageContract)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateCommitMigrationResultsScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameCommitMigrationResults)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}

func GenerateSetStagingCutoffScript(migrationContractStagingAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameSetStagingCutoff)
	return replaceMigrationContractStagingImports(code, migrationContractStagingAddress)
}
