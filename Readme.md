# WithSpecializedGenericMacro

An experimental peer macro expanding generic struct or class to a specialized type, so as to avoid dynamic dispatch.

`@_specialize` attribute: https://forums.swift.org/t/specialize-attribute/1853

## Example

```swift
enum Scoped {
    @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let a: S
    }
}
```

will be expanded to

```swift
enum Namespace {
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let a: S
    }
            
    class Hola<S>: Identifiable where S: Identifiable {
        let id: T
        let a: S
        public typealias T = Int
    }
}
```
