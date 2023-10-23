import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}


public struct WithSpecializedGenericMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        
        
        guard let labeledExprList = node.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }
        
        guard var structDecl = declaration.as(StructDeclSyntax.self) else { return [] }
        
        var specializedDeclName: String?
        var templateTypeName: String?
        var concreteTypeDeclRefExpr: DeclReferenceExprSyntax?
        
        for labeledExpr in labeledExprList {
            switch labeledExpr.label?.text {
            case "namedAs":
                if let namedAsExpr = labeledExpr.expression.as(StringLiteralExprSyntax.self),
                    let literalVal = namedAsExpr.representedLiteralValue {
                    specializedDeclName = literalVal
                }
                else { return [] }
                
            case "specializing":
                if let specializingExpr = labeledExpr.expression.as(StringLiteralExprSyntax.self),
                    let literalVal = specializingExpr.representedLiteralValue {
                    templateTypeName = literalVal
                }
                else { return [] }
                
            case "to":
                if let toTypeExpr = labeledExpr.expression.as(DeclReferenceExprSyntax.self) {
                    concreteTypeDeclRefExpr = toTypeExpr
                }
                else { return [] }
            default:
                return []
            }
            
        }
        
        guard let specializedDeclName, let templateTypeName, let concreteTypeDeclRefExpr else { return  [] }
        
        if structDecl.genericParameterClause != nil {
            if let templateNameToSpecialize = structDecl.genericParameterClause!.parameters.firstIndex(where: { genericParamterSyntax in
                genericParamterSyntax.name.text == templateTypeName
            }) {
                
                

                structDecl.genericParameterClause!.parameters.remove(at: templateNameToSpecialize)
                
                                if (structDecl.genericParameterClause!.parameters.isEmpty) {
                                    structDecl.genericParameterClause = nil
                                }
                
                guard let typealiasDecl = try? TypeAliasDeclSyntax("public typealias \(raw: templateTypeName) = \(raw: concreteTypeDeclRefExpr.baseName)") else {return[]}
                let memberBlockItemOfTypealias = MemberBlockItemSyntax(decl: typealiasDecl)
                    
                structDecl.memberBlock.members.append(memberBlockItemOfTypealias)
                
                
                
//                let uniqueName = context.makeUniqueName(specializedDeclName)
                
                structDecl.name = TokenSyntax(stringLiteral: specializedDeclName)
                
                guard let result = structDecl.as(DeclSyntax.self) else { return [] }
                
                if let thisMacroIndex = structDecl.attributes.firstIndex(where: { it in
                    switch it {
                    case .attribute(let attr):
                        if let identifierTypeSyntax = attr.as(IdentifierTypeSyntax.self) {
                            
                            return identifierTypeSyntax.name.text == Self.macroName
                        }
                        return false
                    case .ifConfigDecl(_):
                        return false
                    }
                }) {
                    structDecl.attributes.remove(at: thisMacroIndex)
                }
                
                
                return [result]
                
            }
            
        }
        
        return []
    }
    
    static let macroName = "WithSpecilizedGeneric"
}


@main
struct WithSpecializedGenericPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        WithSpecializedGenericMacro.self
    ]
}
