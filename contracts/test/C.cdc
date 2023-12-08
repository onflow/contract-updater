import "A"
import "B"

pub contract C {

    pub let StoragePath: StoragePath
    pub let PublicPath: PublicPath

    pub resource interface OuterPublic {
        pub fun getFooFrom(id: UInt64): String
    }

    pub resource Outer : OuterPublic {
        pub let inner: @{UInt64: A.R}

        init() {
            self.inner <- {}
        }

        pub fun getFooFrom(id: UInt64): String {
            return self.borrowResource(id)?.foo() ?? panic("No resource found with given ID")
        }

        pub fun addResource(_ i: @A.R) {
            self.inner[i.uuid] <-! i
        }

        pub fun borrowResource(_ id: UInt64): &{A.I}? {
            return &self.inner[id] as &{A.I}?
        }

        pub fun removeResource(_ id: UInt64): @A.R? {
            return <- self.inner.remove(key: id)
        }

        destroy() {
            destroy self.inner
        }
    }

    init() {
        self.StoragePath = /storage/Outer
        self.PublicPath = /public/OuterPublic

        self.account.save<@Outer>(<-create Outer(), to: self.StoragePath)
        self.account.link<&{OuterPublic}>(self.PublicPath, target: self.StoragePath)

        let outer = self.account.borrow<&Outer>(from: self.StoragePath)!
        outer.addResource(<- B.createR())
    }
}