import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


extension SyntaxCollection {
    @discardableResult
    mutating func removeFirst(predicate: (Element) -> Bool) -> Element? {
        if let firstIndex = firstIndex(where: predicate) {
            return remove(at: firstIndex)
        }
        else { return nil }
    }
}


extension TypeSyntax {
    func isReferencing(identifier: String) -> Bool {
        if let self = self.as(IdentifierTypeSyntax.self) {
            return self.name.text == identifier
        }
        else if let self = self.as(MemberTypeSyntax.self) {
            return self.baseType.isReferencing(identifier: identifier)
        }
        return false
    }
}

protocol ClassOrStructDeclSyntax: DeclSyntaxProtocol {
    var genericParameterClause: GenericParameterClauseSyntax? { get set }
    var genericWhereClause: GenericWhereClauseSyntax? {get set }
    var memberBlock: MemberBlockSyntax {get set}
    var name: TokenSyntax {get set}
    var attributes: AttributeListSyntax {get set}
    
    func `as`<S: DeclSyntaxProtocol>(_ syntaxType: S.Type) -> S?
}

extension ClassDeclSyntax: ClassOrStructDeclSyntax { }
extension StructDeclSyntax: ClassOrStructDeclSyntax { }


public struct WithSpecializedGenericMacro: PeerMacro {
    
    static let macroName = "WithSpecializedGeneric"
    
    enum FieldName: String {
        case specializedDeclFieldName = "namedAs"
        case templateTypeFieldName = "specializing"
        case concreteTypeFieldName = "to"
    }
    
    public enum _DiagnosticMessage {
        case requireLabeledArguments
        case extaneousLabeledArguments
    }
    
    private struct Arguments {
        let specializedDeclName: String
        let templateTypeName: String
        let concreteTypeDeclRefExpr: DeclReferenceExprSyntax
    }

    
    /// Returns true if has `identifier` in generic parameters
    private static func clearGenerics(inside decl: inout some ClassOrStructDeclSyntax, removing identifier: String) -> Bool {
        guard decl.genericParameterClause != nil else { return false}

        let removed = decl.genericParameterClause!.parameters.removeFirst { p in
            p.name.text == identifier
        } 
        
        guard removed != nil else { return false }
        
        if decl.genericWhereClause != nil {
            decl.genericWhereClause!.requirements = decl.genericWhereClause!.requirements.filter { requirement in
                switch requirement.requirement {
                case .conformanceRequirement(let conformanceRequirement):
                    return !conformanceRequirement.leftType.isReferencing(identifier: identifier) && !conformanceRequirement.rightType.isReferencing(identifier: identifier)
                case .sameTypeRequirement(let sameTypeRequirement):
                    return !sameTypeRequirement.leftType.isReferencing(identifier: identifier) && !sameTypeRequirement.rightType.isReferencing(identifier: identifier)
                case .layoutRequirement(_):
                    return true
                }
            }
            
            
            if (decl.genericWhereClause!.requirements.isEmpty) {
                decl.genericWhereClause = nil
            }
        }
        if (decl.genericParameterClause!.parameters.isEmpty) {
            decl.genericParameterClause = nil
        }
        return true
    }
    
    
    private static func clearAttributes(inside decl: inout some ClassOrStructDeclSyntax, removing arguments: Arguments) {
//        var toRemove: [AttributeListSyntax.Index] = []
        for i in decl.attributes.indices {
            switch (decl.attributes[i]) {
            case .attribute(let attr):
                if let attrIdentifier = attr.attributeName.as(IdentifierTypeSyntax.self), attrIdentifier.name.text == Self.macroName {
//                    toRemove.append(i)
                    decl.attributes.remove(at: i)
                }
                return
            case .ifConfigDecl(_):
                break
            }
        }
        
    }
    
    
    
    private static func expansion(
        of arguments: Arguments,
        providingPeersOf structOrClassDecl: some ClassOrStructDeclSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        var structDecl = structOrClassDecl
        
        /// Remove attribute
        clearAttributes(inside: &structDecl, removing: arguments)
        
        let templateTypeName = arguments.templateTypeName
        let concreteTypeDeclRefExpr = arguments.concreteTypeDeclRefExpr
        let specializedDeclName = arguments.specializedDeclName
        
        /// Remove generics
        if !clearGenerics(inside: &structDecl, removing: templateTypeName) {
            /// Multiple expansion
            return []
        }
        
        guard let typealiasDecl = try? TypeAliasDeclSyntax("public typealias \(raw: templateTypeName) = \(raw: concreteTypeDeclRefExpr.baseName)") else {
            return []
        }
        
        /// Add typealias
        let memberBlockItemOfTypealias = MemberBlockItemSyntax(decl: typealiasDecl)
        structDecl.memberBlock.members.append(memberBlockItemOfTypealias)
        
        /// Rename struct
        structDecl.name = TokenSyntax(stringLiteral: specializedDeclName)
        
        
        
        
        
        
//        if structDecl.genericParameterClause != nil {
//            if let templateNameToSpecialize = structDecl.genericParameterClause!.parameters.firstIndex(where: { genericParamterSyntax in
//                genericParamterSyntax.name.text == templateTypeName
//            }) {
//                
//                
//
//                structDecl.genericParameterClause!.parameters.remove(at: templateNameToSpecialize)
//                
//                                if (structDecl.genericParameterClause!.parameters.isEmpty) {
//                                    structDecl.genericParameterClause = nil
//                                }
//                
//                
//
//                
//                if let thisMacroIndex = structDecl.attributes.firstIndex(where: { it in
//                    switch it {
//                    case .attribute(let attr):
//                        if let identifierTypeSyntax = attr.as(IdentifierTypeSyntax.self) {
//                            
//                            return identifierTypeSyntax.name.text == Self.macroName
//                        }
//                        return false
//                    case .ifConfigDecl(_):
//                        return false
//                    }
//                }) {
//                    structDecl.attributes.remove(at: thisMacroIndex)
//                }
//                structDecl.attributes = []
//                
//                return [structDecl.as(DeclSyntax.self)!]
//                
//            }
//            
//        }
        if let result = structDecl.as(DeclSyntax.self) {
            return [result]
        }
        
        return []
    }
    
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        
        guard let labeledExprList = node.arguments?.as(LabeledExprListSyntax.self) else {
            context.diagnose(.init(node: node, message: _DiagnosticMessage.requireLabeledArguments))
            return []
        }
        
        /// Collect parameters
        var specializedDeclName: String?
        var templateTypeName: String?
        var concreteTypeDeclRefExpr: DeclReferenceExprSyntax?
        for labeledExpr in labeledExprList {
            switch labeledExpr.label?.text {
            case FieldName.specializedDeclFieldName.rawValue:
                if let namedAsExpr = labeledExpr.expression.as(StringLiteralExprSyntax.self),
                    let literalVal = namedAsExpr.representedLiteralValue {
                    specializedDeclName = literalVal
                }
                
            case FieldName.templateTypeFieldName.rawValue:
                if let specializingExpr = labeledExpr.expression.as(StringLiteralExprSyntax.self),
                    let literalVal = specializingExpr.representedLiteralValue {
                    templateTypeName = literalVal
                }
                
                
            case FieldName.concreteTypeFieldName.rawValue:
                if let toTypeExpr = labeledExpr.expression.as(DeclReferenceExprSyntax.self) {
                    concreteTypeDeclRefExpr = toTypeExpr
                }
                
            default:
                context.diagnose(.init(node: node, message: _DiagnosticMessage.requireLabeledArguments))
            }
        }
        
        
        guard let specializedDeclName, let templateTypeName, let concreteTypeDeclRefExpr else {
            context.diagnose(.init(node: node, message: _DiagnosticMessage.requireLabeledArguments))
            return []
        }
        
        let args = Arguments(specializedDeclName: specializedDeclName, templateTypeName: templateTypeName, concreteTypeDeclRefExpr: concreteTypeDeclRefExpr)
        
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return try expansion(of: args, providingPeersOf: structDecl, in: context)
        }
        else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            print(classDecl.name.text)
            return try expansion(of: args, providingPeersOf: classDecl, in: context)
        }
        else {
            return []
        }
    }
}




extension WithSpecializedGenericMacro._DiagnosticMessage: DiagnosticMessage {
    public var message: String {
        switch(self) {
        case .requireLabeledArguments:
            return "@\(WithSpecializedGenericMacro.macroName) requires labeled parameters."
        case .extaneousLabeledArguments:
            return "@\(WithSpecializedGenericMacro.macroName) requires labeled parameters."
        }
    }
    
    public var diagnosticID: SwiftDiagnostics.MessageID {
        switch(self) {
        case .requireLabeledArguments:
            return .init(domain: WithSpecializedGenericMacro.macroName, id: "1")
        case .extaneousLabeledArguments:
            return .init(domain: WithSpecializedGenericMacro.macroName, id: "2")
        }
    }
    
    public var severity: SwiftDiagnostics.DiagnosticSeverity {
        return .error
//        switch(self) {
//        case .requireLabeledArguments:
//            return .error
//        }
    }
    
    
}



@main
struct WithSpecializedGenericPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        
        WithSpecializedGenericMacro.self
    ]
}
