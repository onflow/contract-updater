import "DependencyAudit"

access(all) fun main(): DependencyAudit.Boundaries? {
    return DependencyAudit.getBoundaries()
}
