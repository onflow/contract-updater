.PHONY: test
test:
	flow test --cover --covercode="contracts" --coverprofile="coverage.lcov" tests/*.cdc

.PHONY: ci
ci: test