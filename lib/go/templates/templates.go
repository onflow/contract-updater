package templates

import (
	"regexp"

	"github.com/onflow/flow-go-sdk"
)

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../ -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../scripts/... ../../../transactions/...

var (
	placeholderMigrationContractStaging = regexp.MustCompile(`"MigrationContractStaging"`)
)

// Replaces the import alias of the form `import "MigrationContractStaging"` in the given code with the given address,
// resuting in a static import statement of the form `import MigrationContractStaging from 0xADDRESS`.
func replaceMigrationContractStagingImports(code string, migrationContractStagingAddress flow.Address) []byte {
	code = placeholderMigrationContractStaging.ReplaceAllString(
		code,
		"MigrationContractStaging from 0x"+migrationContractStagingAddress.String(),
	)
	return []byte(code)
}
