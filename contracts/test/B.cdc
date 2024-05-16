import "A"

access(all) contract B : A {
    
    access(all) resource R : A.R {
        access(all) fun foo(): String {
            return "foo"
        }
    }
    
    access(all) fun createR(): @R {
        return <-create R()
    }
}