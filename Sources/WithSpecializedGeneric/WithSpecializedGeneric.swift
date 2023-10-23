// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "WithSpecializedGenericMacros", type: "StringifyMacro")


@attached(peer, names: arbitrary)
public macro WithSpecializedGeneric<T>(
    namedAs specializedDeclName: String,
    specializing templateTypeName: String,
    to concreteTypeName: T.Type
) = #externalMacro(module: "WithSpecializedGenericMacros", type: "WithSpecializedGenericMacro")
