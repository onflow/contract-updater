pub contract interface A {
    
    pub resource interface I {
        pub fun foo(): String
    }

    pub resource R : I {
        pub fun foo(): String {
            return "foo"
        }
    }
}