
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
public macro WithSpecializedGeneric<T>(
    namedAs specializedDeclName: String,
    specializing templateTypeName: String,
    to concreteTypeName: T.Type
) = #externalMacro(module: "WithSpecializedGenericMacros", type: "WithSpecializedGenericMacro")
