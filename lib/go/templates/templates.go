package templates

import (
	"fmt"

	"github.com/onflow/flow-go-sdk"
)

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../ -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../scripts/... ../../../transactions/...

var (
	placeholderMigrationContractStagingString = "\"MigrationContractStaging\""
)

func replaceAddresses(code string, migrationContractStagingAddress flow.Address) []byte {
	code = placeholderMigrationContractStagingString.ReplaceAllString(code, "0x"+migrationContractStagingAddress.String())
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
