
/// A peer macro expanding generic struct or class to a specialized type, so as to avoid dynamic dispatch when using generics and type erasure. To some degree, this macro makes generics in Swift work like C++ templates.
///
/// The macro @WithSpecializedGenerics("typealias ...") accepts a list of typealias syntaxes, with a tolerance of the final modifier. The string inside is also parsed with the SwiftSyntax package. This means it works as long as you are providing a list of parsable typealiases. The macro does 6 things for you:
///
/// - Put a specialized type alongside your generic definition.
/// - Add a typealias for each specialized parameter.
/// - Remove the specialized generic parameters.
/// - Remove redundant generic requirements in original where clause.
/// - Copy the generic requirements from your "typealias ... where ..." to the original where clause.
/// - Replace all recursive references to the original type with the newly specialized type.
///
/// ## Example:
///
/// ```
/// enum Scoped {
///     @WithSpecializedGeneric("typealias Hola = Hello<Int>")
///     struct Hello<T> {
///         let a: T
///     }
/// }
/// ```
///
/// produces a new type "Hola", with generic parameters <T> becoming a typealias `T=Int`:
///
/// ```swift
/// enum Scoped {
///     struct Hello<T> {
///         let a: T
///     }
///
///     struct Hola {
///         let a: T
///         public typealias T = Int
///     }
/// }
///
@attached(peer, names: arbitrary)
public macro WithSpecializedGenerics(_ aliases: String) = #externalMacro(module: "WithSpecializedGenericMacros", type: "WithSpecializedGenericsMacro")


/// An expression macro that replaces all occurences of `original`with new expression`replacing` when specializing. This comes handy when you have some specific implementations.
/// - parameters:
///     - original: A valid expression
///     - replacing: A string that will be put in this place in the specialized implementation.
@freestanding(expression)
public macro ReplaceWhenSpecializing<T>(_ original: T, _ replacing: String) -> T = #externalMacro(module: "WithSpecializedGenericMacros", type: "ReplaceWhenSpecializingMacro")


/// An expression macro that replaces all occurences of `original`with new expressions when specializing. This comes handy when you have some specific implementations.
/// - parameters:
///     - original: A valid expression
///     - lookupOn: A dictionary of string that tells rerwiter what to put in this place in the specialized implementation. Keys are the name of specialized class/struct, values are the corresponding string that will be put in this place in the specialized implementation.
///     - fallback:  A string that will be put in this place in the specialized implementation if there's no associated value found on the dictionary.
@freestanding(expression)
public macro ReplaceWhenSpecializing<T>(_ original: T, lookupOn: [String:String], fallback: String) -> T = #externalMacro(module: "WithSpecializedGenericMacros", type: "ReplaceWhenSpecializingMacro")

