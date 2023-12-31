**Archived: Use `@inlinable`.**

# WithSpecializedGenericMacro

<img src="https://github.com/li3zhen1/SpecializedGenericMacros/actions/workflows/swift.yml/badge.svg" alt="swift workflow"> <a href="https://swiftpackageindex.com/li3zhen1/WithSpecializedGeneric"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fli3zhen1%2FWithSpecializedGeneric%2Fbadge%3Ftype%3Dswift-versions" alt="swift package index"></a> <a href="https://swiftpackageindex.com/li3zhen1/WithSpecializedGeneric"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fli3zhen1%2FWithSpecializedGeneric%2Fbadge%3Ftype%3Dplatforms" alt="swift package index"></a>
 
A peer macro expanding generic **struct or class** to a specialized type. This helps Swift to better specialize/optimize your code when you are [exposing public APIs with heavy generics](https://forums.swift.org/t/brave-new-world-best-practices-for-cross-module-optimization/66869) and aware of some specific, frequently used specializations. In a sense, this macro makes generics in Swift work more like C++ templates.

## Example

```swift
enum Namespace {
  @WithSpecializedGenerics("public typealias Hola<S> = Hello<Int, S>;public typealias Hej<S> = Hello<String, S>")
  final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
    let id: T
    let children: Hello<T, S>

    let name = #ReplaceWhenSpecializing("Hello!", "\"¡Hola!\"")

    func greeting(with word: Hello<T, S>) -> Hello<T, S> {
      let _: Hello<T, S> = Hello(id: word.id, children: word.children)
      return Hello<T, S>(id: word.id, children: word.children)
    }

    init(id: T, children: Hello<T, S>) {
      self.id = id
      self.children = children.children
    }
  }
}
```

will be expanded to

```swift
enum Namespace {
    
  final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
    let id: T
    let children: Hello<T, S>

    let name = "Hello!"

    func greeting(with word: Hello<T, S>) -> Hello<T, S> {
      let _: Hello<T, S> = Hello(id: word.id, children: word.children)
      return Hello<T, S>(id: word.id, children: word.children)
    }

    init(id: T, children: Hello<T, S>) {
      self.id = id
      self.children = children.children
    }
  }

  final class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
    let id: T
    let children: Hola<S>

    let name = "¡Hola!"

    func greeting(with word: Hola<S>) -> Hola<S> {
      let _: Hola<S> = Hola(id: word.id, children: word.children)
      return Hola<S>(id: word.id, children: word.children)
    }
    init(id: T, children: Hola<S>) {
      self.id = id
      self.children = children.children
    }
    public typealias T = Int
  }

  final class Hej<S>: Identifiable where S.ID == String, S: Identifiable {
    let id: T
    let children: Hej<S>

    let name = "¡Hola!"

    func greeting(with word: Hej<S>) -> Hej<S> {
      let _: Hej<S> = Hej(id: word.id, children: word.children)
      return Hej<S>(id: word.id, children: word.children)
    }
    init(id: T, children: Hej<S>) {
      self.id = id
      self.children = children.children
    }
    public typealias T = String
  }
}
```

The `enum Namespace` is required since peer macros cannot introduce new name in global scope.


## Details about this macro


The macro `@WithSpecializedGenerics("typealias ...")` accepts a list of `typealias` syntaxes, with a tolerance of the `final` modifier. The string inside is **also parsed with the `SwiftSyntax` package**. This means it works as long as you are providing a list of parsable typealiases. The macro does 6 things for you: 

- Put a specialized type alongside your generic definition.
- Add a typealias for each specialized parameter. 
- Remove the specialized generic parameters.
- Remove redundant generic requirements in original `where` clause.
- Copy the generic requirements from your `"typealias ... where ..."` to the original `where` clause.
- Replace all recursive references to the original type with the newly specialized type.

This package also provides a `#ReplaceWhenSpecialing(#OldExpr#, "NewExpr")` macro, which replaces all occurences of `#OldExpr#` with `NewExpr` when specializing.`#OldExpr#` must be a valid expression, and `NewExpr` can be any string. This comes handy when you have some specific implementations. 



## Misc

For the usecase in [a quadtree data structure (line 48)](https://github.com/li3zhen1/Grape/blob/WithSpecializedGeneric/Sources/NDTree/KDTree.swift), this macro can speed up the construction time of data structure by ~16%, compared to directly using a typealias syntax. Usecases like traversing tree nodes can benefit way more from this.

I have also observed significant performance gain with this approach even when the `-cross-module-optimization` flags are turned on. (from 0.17s to 0.04s in the testcases [here](https://github.com/li3zhen1/Grape/blob/WithSpecializedGeneric/Tests/ForceSimulationTests/MiserableGraphTest.swift))

> [!NOTE]
> For generic functions try [`@_specialize` attribute](https://github.com/apple/swift/blob/main/docs/ReferenceGuides/UnderscoredAttributes.md#_specialize).


> [!NOTE]
> Currently this macro does not take special care for `AnotherNamespace.StructOrClassWithSameName`, and hence it might introduce undesired code when encountering this.


> [!NOTE]
> If you’re adding an extension to the original generic type in the same file, and encountered error `Circular reference`, moving the extension to another file can solve this. This is probably similar to the issue discussed here: https://github.com/apple/swift/issues/66450 .
