package templates

import (
	"fmt"
	"regexp"

	"github.com/onflow/flow-go-sdk"
)

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../ -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../scripts/... ../../../transactions/...

var (
	placeholderMigrationContractStaging = regexp.MustCompile(`"MigrationContractStaging"`)
)

func replaceMigrationContractStagingImports(code string, migrationContractStagingAddress flow.Address) []byte {
	code = placeholderMigrationContractStaging.ReplaceAllString(code, "0x"+migrationContractStagingAddress.String())
	return []byte(code)
}

func withHexPrefix(address string) string {
	if address == "" {
		return ""
	}

	if address[0:2] == "0x" {
		return address
	}

	return fmt.Sprintf("0x%s", address)
}
