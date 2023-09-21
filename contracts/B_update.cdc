import A from 0x045a1763c93006ca

access(all) contract B : A {
    
    access(all) resource R : A.I {
        access(all) view fun foo(): String {
            return "foo"
        }
        access(all) view fun bar(): String {
            return "bar"
        }
    }
    
    access(all) fun createR(): @R {
        return <-create R()
    }
}