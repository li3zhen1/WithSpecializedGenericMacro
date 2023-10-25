# WithSpecializedGenericMacro

<img src="https://github.com/li3zhen1/SpecializedGenericMacros/actions/workflows/swift.yml/badge.svg" alt="swift workflow">

An experimental peer macro expanding generic **struct or class** to a specialized type, so as to avoid dynamic dispatch.

This macro simply put a specialized type alongside your generic definition, by removing the generic parameter, adding a typealias for the removed parameter. It also replaces all recursive references to the original type with the new specialized type.

For the usecase in [a quadtree data structure (line 48)](https://github.com/li3zhen1/Grape/blob/WithSpecializedGeneric/Sources/NDTree/KDTree.swift), this macro can speed up the construction time of data structure by ~15%, compared to directly using a typealias syntax. (Usecases like traversing tree nodes can probably benefit way more from this)


> [!NOTE]
> For generic functions try [`@_specialize` attribute](https://github.com/apple/swift/blob/main/docs/ReferenceGuides/UnderscoredAttributes.md#_specialize).


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
+            let test: Hola<S> = Hola()
+            return Hola<S>()
+        }
+        public typealias T = Int
+    }
}
```

The `enum Namespace` is required since peer macros cannot introduce new name in global scope.

> [!IMPORTANT]
> Currently this macro does not take special care for `AnotherNamespace.StructOrClassWithSameName`, and hence it might introduce undesired code when encountering this.


> [!NOTE]
> If you’re adding an extension to the original genric type on the same file, and encountered error `Circular reference`, move the extension to another file can solve this.
