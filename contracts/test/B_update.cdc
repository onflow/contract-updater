import A from 0x0000000000000009

access(all) contract B : A {
    
    access(all) resource R : A.I {
        access(all) fun foo(): String {
            return "foo"
        }
        access(all) fun bar(): String {
            return "bar"
        }
    }
    
    access(all) fun createR(): @R {
        return <-create R()
    }
}