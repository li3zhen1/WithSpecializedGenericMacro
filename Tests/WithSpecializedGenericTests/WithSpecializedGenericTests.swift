import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WithSpecializedGenericMacros)
import WithSpecializedGenericMacros

let testMacros: [String: Macro.Type] = [
//    "stringify": StringifyMacro.self,
    "WithSpecializedGeneric": WithSpecializedGenericMacro.self,
]
#endif

final class WithSpecializedGenericTests: XCTestCase {
    
    
    func testSimpleGenericStruct() throws {
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
    
    
    
    func testGenericStructWithSameTypeRequirements() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
                struct Hello<T> where T == Int {
                    let a: T
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                struct Hello<T> where T == Int {
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
    
    
    func testGenericStructWithConformanceRequirements() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
                struct Hello<T> where T: Hashable {
                    let a: T
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                struct Hello<T> where T: Hashable {
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

    
    
    
    func testComplexGenericClass() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
                class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T
                    let a: S
                }
            }
            """,
            expandedSource: """
            enum Scoped {
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
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    
    func testMultipleComplexGenericClass() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
                @WithSpecializedGeneric(namedAs: "Hej", specializing: "T", to: String)
                class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T
                    let a: S
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T
                    let a: S
                }
                    class Hola<S>: Identifiable where S: Identifiable {
                                let id: T
                                let a: S
                        public typealias T = Int
                    }
                    class Hej<S>: Identifiable where S: Identifiable {
                                let id: T
                                let a: S
                        public typealias T = String
                    }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}
