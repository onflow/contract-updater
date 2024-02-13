package templates_test

import (
	"testing"

	"github.com/onflow/contract-updater/lib/go/templates"
	"github.com/onflow/flow-go-sdk/test"
	"github.com/stretchr/testify/assert"
)

func TestGenerateStageContractScript(t *testing.T) {
	addresses := test.AddressGenerator()
	contractAlias := addresses.New()

	template := templates.GenerateStageContractScript(contractAlias)
	assert.NotNil(t, template)
	assert.Contains(t, string(template), contractAlias.String())
}
