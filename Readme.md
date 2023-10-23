# WithSpecializedGenericMacro


An experimental peer macro expanding generic struct or class to a specialized type, so as to avoid dynamic dispatch. (?)


`@_specialize` attribute: https://forums.swift.org/t/specialize-attribute/1853


```swift
enum Scoped {
    @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
    struct Hello<T> {
        let a: T
    }
}
```

```swift
enum Scoped {
    struct Hello<T> {
        let a: T
    }
    struct Hola {
        let a: T
        public typealias T = Int
    }
}
```
