package contracts

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../contracts -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../contracts

import (
	"regexp"

	_ "github.com/kevinburke/go-bindata"

	"github.com/onflow/contract-updater/lib/go/contracts/internal/assets"
)

var (
	placeholderNonFungibleToken = regexp.MustCompile(`"MigrationContractStaging"`)
)

const (
	filenameMigrationContractStaging = "MigrationContractStaging.cdc"
)

func MigrationContractStaging() []byte {
	code := assets.MustAssetString(filenameMigrationContractStaging)
	return []byte(code)
}
