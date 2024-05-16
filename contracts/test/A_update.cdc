access(all) contract interface A {
    
    access(all) resource interface I {
        access(all) fun foo(): String
        access(all) fun bar(): String
    }

    access(all) resource R : I {
        access(all) fun foo(): String {
            return "foo"
        }
        access(all) fun bar(): String {
            return "bar"
        }
    }
}