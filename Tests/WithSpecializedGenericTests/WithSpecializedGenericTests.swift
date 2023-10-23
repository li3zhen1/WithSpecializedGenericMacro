import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WithSpecializedGenericMacros)
import WithSpecializedGenericMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "WithSpecializedGeneric": WithSpecializedGenericMacro.self,
]
#endif

final class WithSpecializedGenericTests: XCTestCase {
    func testMacro() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
                struct Hello<T> {
                    let a: T
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                struct Hello<T> {
                    let a: T
                }
                    struct Hola {
                                let a: T
                        public typealias T = Int
                    }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
