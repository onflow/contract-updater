import "A"

pub contract B : A {
    
    pub resource R : A.I {
        pub fun foo(): String {
            return "foo"
        }
    }
    
    pub fun createR(): @R {
        return <-create R()
    }
}