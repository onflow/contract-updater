access(all) contract interface A {
    
    access(all) resource interface I {
        access(all) view fun foo(): String
        access(all) view fun bar(): String
    }
}
