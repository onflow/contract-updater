import A from 0x045a1763c93006ca

pub contract B : A {
    
    pub resource R : A.I {
        pub fun foo(): String {
            return "foo"
        }
        pub fun bar(): String {
            return "bar"
        }
    }
    
    pub fun createR(): @R {
        return <-create R()
    }
}