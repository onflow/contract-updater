pub contract interface A {
    
    pub resource interface I {
        pub fun foo(): String
        pub fun bar(): String
    }

    pub resource R : I {
        pub fun foo(): String {
            return "foo"
        }
        pub fun bar(): String {
            return "bar"
        }
    }
}