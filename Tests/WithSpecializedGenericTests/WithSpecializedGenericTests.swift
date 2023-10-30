import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WithSpecializedGenericMacros)
import WithSpecializedGenericMacros

let testMacros: [String: Macro.Type] = [
//    "stringify": StringifyMacro.self,
//    "WithSpecializedGeneric": WithSpecializedGenericMacro.self,
    "WithSpecializedGenerics": WithSpecializedGenericsMacro.self,
    "ReplaceWhenSpecializing": ReplaceWhenSpecializingMacro.self,
]
#endif

final class WithSpecializedGenericTests: XCTestCase {
    
 
    
    
    func testGenericStructWithSameTypeRequirements() throws {
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion(
            """
            enum Scoped {
                @WithSpecializedGenerics("typealias Hola = Hello<Int>")
                struct Hello<T> where T: NumericalBlabla {
                    let a: T
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                struct Hello<T> where T: NumericalBlabla {
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
                @WithSpecializedGenerics("typealias Hola=Hello<Int>")
                struct Hello<T> where T: NumericalBlabla {
                    let a: T
                }
            }
            """,
            expandedSource: """
            enum Scoped {
                struct Hello<T> where T: NumericalBlabla {
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
                @WithSpecializedGenerics("typealias Hola<Double> = Hello<Double, S>")
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

                class Hola<T>: Identifiable where T: Hashable, S.ID == T {
                        let id: T
                        let a: S
                        public typealias S = S
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
                @WithSpecializedGenerics("typealias Hola<S> = Hello<Int, S>;typealias Hej<S> = Hello<String, S> where S: Codable")
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

                class Hej<S>: Identifiable where S.ID == String, S: Identifiable , S: Codable {
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
                
                @WithSpecializedGenerics("public typealias Hola<S> = Hello<Int, S>")
                struct Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T
                    init(id: T) {
                        self.id = id
                    }
                }
                
            }
            """,
            expandedSource: """
            enum Scoped {
                
                struct Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T
                    init(id: T) {
                        self.id = id
                    }
                }

                struct Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
                        let id: T
                        init(id: T) {
                                self.id = id
                        }
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
    
    
    
    
    func testNestedClass() throws {
        #if canImport(WithSpecializedGenericMacros)
        let original = """
            enum Scoped {
                
                
                @WithSpecializedGenerics("public typealias Hola<S> = Hello<Int, S>")
                final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T = #ReplaceWhenSpecializing("1", "\\"2\\"")
                    let children: Hello<T, S>
                    

                    func greeting(with word: Hello<T, S>) -> Hello<T, S> {
                        let _: Hello<T, S> = Hello(id: word.id, children: word.children)
                        return Hello<T, S>(id: word.id, children: word.children)
                    }
                   
                    init(id: T, children: Hello<T,S>) {
                        self.id = id
                        self.children = children.children
                    }
                }
                
            }
            """
//        print(original)
        assertMacroExpansion(
            original,
            expandedSource: """
            enum Scoped {
                
                
                final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
                    let id: T =         "1"
                    let children: Hello<T, S>
                    

                    func greeting(with word: Hello<T, S>) -> Hello<T, S> {
                        let _: Hello<T, S> = Hello(id: word.id, children: word.children)
                        return Hello<T, S>(id: word.id, children: word.children)
                    }
                   
                    init(id: T, children: Hello<T,S>) {
                        self.id = id
                        self.children = children.children
                    }
                }

                final class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
                        let id: T = "2"
                        let children: Hola<S>
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
                
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMultipleReplacement() {
        
        #if canImport(WithSpecializedGenericMacros)
        assertMacroExpansion("""
        enum Namespace {
          @WithSpecializedGenerics("public typealias Hola<S> = Hello<Int, S>;public typealias Hej<S> = Hello<String, S>")
          final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
            let id: T
            let children: Hello<T, S>

            let name = #ReplaceWhenSpecializing("Hello!", lookupOn: [
                "Hola" : "\\"¡Hola!\\"",
                "Hej"  : "\\"Hej!!!\\""
            ], fallback: "Unknown")

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
        """
        , expandedSource: """
        enum Namespace {
          final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
            let id: T
            let children: Hello<T, S>

            let name =     "Hello!"

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
                  let name = "Hej!!!"
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
        """, macros: testMacros)
        #endif
    }
    
//    func testSimulation() {
//#if canImport(WithSpecializedGenericMacros)
//assertMacroExpansion(
//    simulationCode,
//    expandedSource: """
//    enum Scoped {
//        
//        
//        final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
//            let id: T =         1
//            let children: Hello<T, S>
//            
//
//            func greeting(with word: Hello<T, S>) -> Hello<T, S> {
//                let _: Hello<T, S> = Hello(id: word.id, children: word.children)
//                return Hello<T, S>(id: word.id, children: word.children)
//            }
//           
//            init(id: T, children: Hello<T,S>) {
//                self.id = id
//                self.children = children.children
//            }
//        }
//
//        final class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
//                let id: T = 2
//                let children: Hola<S>
//                func greeting(with word: Hola<S>) -> Hola<S> {
//                        let _: Hola<S> = Hola(id: word.id, children: word.children)
//                        return Hola<S>(id: word.id, children: word.children)
//                }
//                init(id: T, children: Hola<S>) {
//                        self.id = id
//                        self.children = children.children
//                }
//                public typealias T = Int
//        }
//        
//    }
//    """,
//    macros: testMacros
//)
//#else
//throw XCTSkip("macros are only supported when running tests for the host platform")
//#endif
//    }

}
