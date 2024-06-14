import "DependencyAudit"

access(all) fun main(): UFix64 {
    return DependencyAudit.getCurrentFailureProbability()
}
