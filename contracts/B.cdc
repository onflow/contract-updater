import "A"

access(all) contract B : A {
    
    access(all) resource R : A.I {
        access(all) view fun foo(): String {
            return "foo"
        }
    }
    
    access(all) fun createR(): @R {
        return <-create R()
    }
}