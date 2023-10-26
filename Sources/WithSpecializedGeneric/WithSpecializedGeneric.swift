
/// A macro that put a specialized type alongside your generic definition
///
/// ```
/// enum Scoped {
///     @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
///     struct Hello<T> {
///         let a: T
///     }
/// }
/// ```
///
/// produces a new type "Hola", with generic parameters <T> becoming a typealias `T=Int`
@attached(peer, names: arbitrary)
public macro WithSpecializedGenerics(_ aliases: String) = #externalMacro(module: "WithSpecializedGenericMacros", type: "WithSpecializedGenericsMacro")

