import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public enum WithSpecializedGenericsMacroError: Error {
    case unknown
    case unexpectedlyMeetMemberTypeIndentifier(String)
}


public struct ReplaceWhenSpecializingMacro: ExpressionMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        return node.argumentList.first?.expression ?? ""
    }
    
    
}


public struct WithSpecializedGenericsMacro: PeerMacro {
    
    public static let macroName: String = "WithSpecializedGenerics"
    
    public static let replaceMacroName: String = "ReplaceWhenSpecializing"
    
    private static func expansion(
        of arguments: InlinedTypealiasParameter,
        providingPeersOf structOrClassDecl: some ClassOrStructDeclSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> SwiftSyntax.DeclSyntax? {
        var structOrClassDecl = structOrClassDecl
        
        
        guard let genericParameterClause = structOrClassDecl.genericParameterClause else { return nil }
        let originalGenericParamNames = genericParameterClause.parameters.map { $0.name.text }
        
        let rewriter = try InlinedGenericsRewriter(parameter: arguments, originalRightParameterNames: originalGenericParamNames)
        
        structOrClassDecl.name = TokenSyntax(stringLiteral: arguments.leftName)
        for mapping in rewriter.replacementsMapping {
            guard let nn = mapping.newName else { continue }
            guard let typealiasDecl = try? TypeAliasDeclSyntax("public typealias \(raw: mapping.oldName) = \(raw: nn)") else {
                return nil
            }
            let memberBlockItemOfTypealias = MemberBlockItemSyntax(decl: typealiasDecl)
            structOrClassDecl.memberBlock.members.append(memberBlockItemOfTypealias)
        }

       
        if let rewritten = rewriter.rewrite(structOrClassDecl).formatted().as(SwiftSyntax.DeclSyntax.self) {
            return rewritten
        }
        
        return nil
    }
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
//        return [
//            """
//                final class Hola<S>: Identifiable where S.ID == Int, S: Identifiable {
//                        let id: Int
//                        let children: Hola<S>
//                        func greeting(with word: Hola<S>) -> Hola<S> {
//                                let _: Hola<S> = Hola(id: word.id, children: word.children)
//                                return Hola<S>(id: word.id, children: word.children)
//                        }
//                        init(id: Int, children: Hola<S>) {
//                                self.id = id
//                                self.children = children.children
//                        }
//                }
//            """
//        ]
        
        guard let labeledExprList = node.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }
        
        guard let mappingStringLiteral = labeledExprList.first?.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue else {
            return []
        }
        
        let parsedMapping = try InlinedTypealiasParameter.parseFromSwiftSource(mappingStringLiteral)
        
        var results = [DeclSyntax]()
        for parsedMap in parsedMapping {
            if let structDecl = declaration.as(StructDeclSyntax.self) {
                if let rewritten = try expansion(of: parsedMap, providingPeersOf: structDecl, in: context) {
                    results.append(rewritten)
                }
            }
            else if let classDecl = declaration.as(ClassDeclSyntax.self) {
                if let rewritten = try expansion(of: parsedMap, providingPeersOf: classDecl, in: context) {
                    results.append(rewritten)
                }
            }
        }
        
        return results
                
    }
    
    
}

@main
struct WithSpecializedGenericMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WithSpecializedGenericsMacro.self,
        ReplaceWhenSpecializingMacro.self,
    ]
}
