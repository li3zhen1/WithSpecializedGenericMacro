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
    
    func modifyReference(from identifier: String, to: String) -> TypeSyntax {
        if var self = self.as(IdentifierTypeSyntax.self) {
            if self.name.text == identifier {
                self.name = TokenSyntax(stringLiteral: to)
            }
            return self.as(TypeSyntax.self)!
        }
        else if var self = self.as(MemberTypeSyntax.self) {
            self.baseType = self.baseType.modifyReference(from: identifier, to: to)
            return self.as(TypeSyntax.self)!
        }
        return self
    }
}


protocol ClassStructOrExtensionSyntax: DeclSyntaxProtocol {
    var genericWhereClause: GenericWhereClauseSyntax? {get set }
    var memberBlock: MemberBlockSyntax {get set}
    var attributes: AttributeListSyntax {get set}
}


protocol ClassOrStructDeclSyntax: ClassStructOrExtensionSyntax {
    var genericParameterClause: GenericParameterClauseSyntax? { get set }
    var name: TokenSyntax {get set}
}

extension ClassDeclSyntax: ClassOrStructDeclSyntax { }
extension StructDeclSyntax: ClassOrStructDeclSyntax { }
extension ExtensionDeclSyntax: ClassStructOrExtensionSyntax { }




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
    private static func hasGenericParameterToRemove(inside decl: some ClassOrStructDeclSyntax, removing identifier: String) -> Bool {
        guard decl.genericParameterClause != nil else { return false}

        let index = decl.genericParameterClause!.parameters.first { p in
            p.name.text == identifier
        } 
        
        guard index != nil else { return false }
//
//        if decl.genericWhereClause != nil {
//            decl.genericWhereClause!.requirements = decl.genericWhereClause!.requirements.filter { requirement in
//                switch requirement.requirement {
//                case .conformanceRequirement(let conformanceRequirement):
//                    return !conformanceRequirement.leftType.isReferencing(identifier: identifier) && !conformanceRequirement.rightType.isReferencing(identifier: identifier)
//                case .sameTypeRequirement(let sameTypeRequirement):
//                    return !sameTypeRequirement.leftType.isReferencing(identifier: identifier) && !sameTypeRequirement.rightType.isReferencing(identifier: identifier)
//                case .layoutRequirement(_):
//                    return true
//                }
//            }
//            
//            
//            if (decl.genericWhereClause!.requirements.isEmpty) {
//                decl.genericWhereClause = nil
//            }
//        }
//        if (decl.genericParameterClause!.parameters.isEmpty) {
//            decl.genericParameterClause = nil
//        }
        return true
    }
    
    
    private static func clearAttributes(inside decl: inout some ClassStructOrExtensionSyntax, removing arguments: Arguments) {
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
    
//    private static func expansion(
//        of arguments: Arguments,
//        providingPeersOf extensionDecl: ExtensionDeclSyntax,
//        in context: some SwiftSyntaxMacros.MacroExpansionContext
//    ) throws -> [SwiftSyntax.DeclSyntax] {
//        var extensionDecl = extensionDecl
//        clearAttributes(inside: &extensionDecl, removing: arguments)
//        let templateTypeName = arguments.templateTypeName
//        let concreteTypeDeclRefExpr = arguments.concreteTypeDeclRefExpr
//        let specializedDeclName = arguments.specializedDeclName
//        
//        guard let decoratedName = extensionDecl.extendedType.as(MemberTypeSyntax.self)?.name ?? extensionDecl.extendedType.as(IdentifierTypeSyntax.self)?.name else { return [] }
//        
//        /// TODO: If extension has where clause
//        let rewiter = SpecializeGenericRewriter(
//            parameter: .init(
//                oldName: decoratedName.text,
//                oldGenericParameterList: extensionDecl.genericParameterClause!.parameters,
//                newName: specializedDeclName,
//                from: templateTypeName,
//                to: concreteTypeDeclRefExpr
//            )
//        )
//        
//        if let result = rewiter.rewrite(extensionDecl).as(DeclSyntax.self) {
//            
//            return [result]
//        }
//        
//        return []
//    }
    
    
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
        if !hasGenericParameterToRemove(inside: structDecl, removing: templateTypeName) {
            /// Multiple expansion
            return []
        }
        
        let rewiter = SpecializeGenericRewriter(
            parameter: .init(
                oldName: structDecl.name.text,
                oldGenericParameterList: structDecl.genericParameterClause!.parameters,
                newName: specializedDeclName,
                from: templateTypeName,
                to: concreteTypeDeclRefExpr
            )
        )
        
        
        guard let typealiasDecl = try? TypeAliasDeclSyntax("public typealias \(raw: templateTypeName) = \(raw: concreteTypeDeclRefExpr.baseName)") else {
            return []
        }
        
        /// Add typealias
        let memberBlockItemOfTypealias = MemberBlockItemSyntax(decl: typealiasDecl)
//        for i in structDecl.memberBlock.members.indices {
//            structDecl.memberBlock.members[i] = structDecl.memberBlock.members[i].trimmed
//        }
        structDecl.memberBlock.members.append(memberBlockItemOfTypealias)
        
        /// Rename struct
        structDecl.name = TokenSyntax(stringLiteral: specializedDeclName)
        
        
        
        if let result = rewiter.rewrite(structDecl).as(DeclSyntax.self) {
            
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
            return try expansion(of: args, providingPeersOf: classDecl, in: context)
        }
//        else if let extensionDecl = declaration.as(ExtensionDeclSyntax.self) {
//            return try expansion(of: args, providingPeersOf: extensionDecl, in: context)
//        }
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
    }
    
    
}



@main
struct WithSpecializedGenericPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        
        WithSpecializedGenericMacro.self
    ]
}
