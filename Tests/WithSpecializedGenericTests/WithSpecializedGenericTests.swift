import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WithSpecializedGenericMacros)
import WithSpecializedGenericMacros

let testMacros: [String: Macro.Type] = [
//    "stringify": StringifyMacro.self,
    "WithSpecializedGeneric": WithSpecializedGenericMacro.self,
    "WithSpecializedGenerics": WithSpecializedGenericsMacro.self,
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

                struct Hola   {
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

                struct Hola    {
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

                struct Hola    {
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
            
                class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
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
                    class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
                                let id: T
                                let a: S
                        public typealias T = Int
                    }
                    class Hej<S>: Identifiable where S.ID == String, S: Identifiable {
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
    
    
    
    func testMultipleComplexGenericClassWithFunctionInitializer() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
                @WithSpecializedGeneric(namedAs: "Hej", specializing: "T", to: String)
                class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T
                    let childre: Hello<T, S>
            
                    func greeting(with word: Hello<T, S>) -> Hello<T, S> {
                        let b: Hello<T, S> = Hello()
                        return Hello<T, S>()
                    }
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T
                    let childre: Hello<T, S>

                    func greeting(with word: Hello<T, S>) -> Hello<T, S> {
                        let b: Hello<T, S> = Hello()
                        return Hello<T, S>()
                    }
                }
                    class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
                                let id: T
                                let childre: Hola<S>

                                func greeting(with word: Hola<S>) -> Hola<S> {
                                        let b: Hola<S> = Hola()
                                        return Hola<S>()
                                }
                        public typealias T = Int
                    }
                    class Hej<S>: Identifiable where S.ID == String, S: Identifiable {
                                let id: T
                                let childre: Hej<S>

                                func greeting(with word: Hej<S>) -> Hej<S> {
                                        let b: Hej<S> = Hej()
                                        return Hej<S>()
                                }
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
    
    
    
    
    func testNestedClass() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGeneric(namedAs: "IntNode", specializing: "T", to: Int)
                struct Node<T> where T: Hashable {
                    let children: [Node<T>]
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                struct Node<T> where T: Hashable {
                    let children: [Node<T>]
                }

                struct IntNode    {
                                let children: [IntNode  ]
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

    
    func testDSLResolve() throws {
        

        
#if canImport(WithSpecializedGenericMacros)
assertMacroExpansion(
    """
    enum Scoped {
        @WithSpecializedGenerics(\"""
        Nihao {
            T = Int
        }
        Hej {
            V = String
            T = Double
        }
        \""")
        struct Node<T> where T: Hashable {
            let children: [Node<T>]
        }
    }
    """,
    expandedSource: """
    enum Scoped {
        struct Node<T> where T: Hashable {
            let children: [Node<T>]
        }

        struct IntNode    {
                        let children: [IntNode  ]
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
    

}
