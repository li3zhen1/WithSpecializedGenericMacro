# WithSpecializedGenericMacro

<img src="https://github.com/li3zhen1/SpecializedGenericMacros/actions/workflows/swift.yml/badge.svg" alt="swift workflow">

An experimental peer macro expanding generic **struct or class** to a specialized type, so as to avoid dynamic dispatch.

This macro simply put a specialized type alongside your generic definition, by aliasing the generic type to a concrete type as a member of the struct/class, and replacing all recursive references to the original type with the new specialized type.

For generic functions try `@_specialize` attribute: https://forums.swift.org/t/specialize-attribute/1853

## Example

```swift
enum Scoped {
    @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let child: Hello<T, S>
        ...
        func spawn() -> Hello<T,S> {
            let test: Hello<T, S> = Hello()
            return Hello<T, S>()
        }
    }
}
```

will be expanded to

```diff
enum Namespace {
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let child: Hello<T, S>
        ...
        func spawn() -> Hello<T,S> {
            let test: Hello<T, S> = Hello()
            return Hello<T, S>()
        }
    }
    
+    class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
+        let id: T
+        let child: Hola<S>
+        ...
+        func spawn() -> Hola<S> {
+            let test: [Hola<S>] = [Hola()]
+            return Hola<S>()
+        }
+        public typealias T = Int
+    }
}
```

The `enum Namespace` is required since peer macros cannot introduce new name in global scope.

> [!IMPORTANT]
> Currently this macro does not take special care for `AnotherNamespace.StructOrClassWithSameName`, and hence it might introduce undesired code when encountering this.
