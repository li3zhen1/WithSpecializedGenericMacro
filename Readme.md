# WithSpecializedGenericMacro

An experimental peer macro expanding generic **struct or class** to a specialized type, so as to avoid dynamic dispatch.

This macro simply put a specialized type alongside your generic definition, by aliasing the generic type to a concrete type as a member of the struct/class.

For generic functions try `@_specialize` attribute: https://forums.swift.org/t/specialize-attribute/1853

## Example

```swift
enum Scoped {
    @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
    @WithSpecializedGeneric(namedAs: "Hej", specializing: "T", to: String)
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let a: S
    }
}
```

will be expanded to

```diff
enum Namespace {
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let a: S
    }
    
+    class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
+        let id: T
+        let a: S
+        public typealias T = Int
+    }
+    class Hej<S>: Identifiable where S.ID == String, S: Identifiable {
+        let id: T
+        let a: S
+        public typealias T = String
+    }
}
```

The `enum Namespace` is required to make compiler happy since peer macros cannot create new name in global scope.
