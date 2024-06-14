import "DependencyAudit"

access(all) fun main(): Boolean {
    return DependencyAudit.panicOnUnstaged
}
