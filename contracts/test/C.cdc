import "A"
import "B"

access(all) contract C {

    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    access(all) resource interface OuterPublic {
        access(all) fun getFooFrom(id: UInt64): String
    }

    access(all) resource Outer : OuterPublic {
        access(all) let inner: @{UInt64: {A.R}}

        init() {
            self.inner <- {}
        }

        access(all) fun getFooFrom(id: UInt64): String {
            return self.borrowResource(id)?.foo() ?? panic("No resource found with given ID")
        }

        access(all) fun addResource(_ i: @{A.R}) {
            self.inner[i.uuid] <-! i
        }

        access(all) fun borrowResource(_ id: UInt64): &{A.I}? {
            return &self.inner[id] as &{A.I}?
        }

        access(all) fun removeResource(_ id: UInt64): @{A.R}? {
            return <- self.inner.remove(key: id)
        }
    }

    init() {
        self.StoragePath = /storage/Outer
        self.PublicPath = /public/OuterPublic

        self.account.storage.save<@Outer>(<-create Outer(), to: self.StoragePath)
        let cap = self.account.capabilities.storage.issue<&{OuterPublic}>(self.StoragePath)
        self.account.capabilities.publish(cap, at: self.PublicPath)

        let outer = self.account.storage.borrow<&Outer>(from: self.StoragePath)!
        outer.addResource(<- B.createR())
    }
}