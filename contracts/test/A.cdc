access(all) contract interface A {
    
    access(all) resource interface I {
        access(all) fun foo(): String
    }

    access(all) resource interface R : I {
        access(all) fun foo(): String {
            return "foo"
        }
    }
}