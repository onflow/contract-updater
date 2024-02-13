package templates_test

import (
	"strings"
	"testing"

	"github.com/onflow/contract-updater/lib/go/templates"
	"github.com/onflow/flow-go-sdk/test"
	"github.com/stretchr/testify/assert"
)

func TestIsValidatedScript(t *testing.T) {
	addresses := test.AddressGenerator()
	contractAlias := addresses.New()

	template := templates.GenerateIsValidatedScript(contractAlias)
	assert.NotNil(t, template)

	importLine := strings.Split(string(template), "\n")[0]
	expectedImportLine := `import MigrationContractStaging from 0x` + contractAlias.String()
	assert.Equal(t, expectedImportLine, importLine)
}

func TestGenerateStageContractScript(t *testing.T) {
	addresses := test.AddressGenerator()
	contractAlias := addresses.New()

	template := templates.GenerateStageContractScript(contractAlias)
	assert.NotNil(t, template)

	importLine := strings.Split(string(template), "\n")[0]
	expectedImportLine := `import MigrationContractStaging from 0x` + contractAlias.String()
	assert.Equal(t, expectedImportLine, importLine)
}
