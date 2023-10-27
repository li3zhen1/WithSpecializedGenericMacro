//
//  File.swift
//  
//
//  Created by li3zhen1 on 10/25/23.
//

import SwiftSyntax
import SwiftParser


final class InlinedGenericsRewriter: SyntaxRewriter {
    
    
    
    
    
    
    
    struct ReplacementMapping {
        let index: Int, oldName: String, newName: String?
        var shouldReplaceOrRemove: Bool { newName != nil }
    }
    
    let parameter: InlinedTypealiasParameter
    
    let replacements: [InlinedTypealiasParameter.GenericParameterMapping]
    let originalRightParameterNames: [String]
    let replacementsMapping: [ReplacementMapping]
    
    init(
        parameter: InlinedTypealiasParameter,
        originalRightParameterNames: [String]
    ) throws {
        self.parameter = parameter

        self.originalRightParameterNames = originalRightParameterNames
        
        let mapping = try parameter.getMapping()
        
        self.replacementsMapping = originalRightParameterNames.enumerated().map { (index, oldName) in
            let newName: String? = if let entry = mapping.first (where: { $0.index == index }) {
                entry.newName
            } else {
                nil
            }
            return ReplacementMapping(
                index: index,
                oldName: oldName,
                newName: newName
            )
        }
        
        self.replacements = mapping
    }
    
    
    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        guard node.name.text == parameter.rightName else { return node.as(TypeSyntax.self)! }
        var node = node
        
        if node.genericArgumentClause != nil {
            transformGenericArgumentClause(clause: &node.genericArgumentClause!)
        }
        node.name = TokenSyntax(stringLiteral: parameter.leftName)
        return node.as(TypeSyntax.self)!
    }
    
    
    override func visit(_ node: GenericSpecializationExprSyntax) -> ExprSyntax {
        guard var declRef = node.expression.as(DeclReferenceExprSyntax.self),
              declRef.baseName.text == parameter.rightName else { return node.as(ExprSyntax.self)! }
        
        var node = node
        transformGenericArgumentClause(clause: &node.genericArgumentClause)
        declRef.baseName = TokenSyntax(stringLiteral: parameter.leftName)
        node.expression = declRef.as(ExprSyntax.self)!
        
        return node.as(ExprSyntax.self)!
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        
        var node = node
        
        if node.baseName.text == parameter.rightName {
            node.baseName = TokenSyntax(stringLiteral: parameter.leftName)
        }
        
        return node.as(ExprSyntax.self)!
    }
    
    
    override func visit(_ node: GenericParameterClauseSyntax) -> GenericParameterClauseSyntax {
        var node = node
        transformGenericParameterClause(clause: &node)
        return node
    }
    
    override func visit(_ node: GenericWhereClauseSyntax) -> GenericWhereClauseSyntax {
        var node = node
        transformGenericWhereClause(clause: &node)
        return node
    }
    
    
    override func visit(_ node: AttributeListSyntax) -> AttributeListSyntax {
        return node.filter { item in
            switch item {
            case .attribute(let attr):
                if let nameIdentifier = attr.attributeName.as(IdentifierTypeSyntax.self) {
                    return nameIdentifier.name.text != WithSpecializedGenericsMacro.macroName
                }
                else {
                    return true
                }
            case .ifConfigDecl(_):
                return true
            }
        }
    }
    
    
    
    
    
    override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
        return super.visit(node).trimmed
    }
    
    
    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        return super.visit(node).trimmed
    }
    
    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        var node = node
        node.leftBrace = node.leftBrace.trimmed
        node.rightBrace = node.rightBrace.trimmed
        for i in node.statements.indices {
            node.statements[i] = node.statements[i].trimmed
        }
        return super.visit(node).trimmed
    }
    
    override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
        var node = node
        node.leftBrace = node.leftBrace.trimmed
        node.rightBrace = node.rightBrace.trimmed
        for i in node.members.indices {
            node.members[i] = node.members[i].trimmed
        }
        return super.visit(node).trimmed
    }
    
    override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
        return super.visit(node).trimmed
    }
    
    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        return super.visit(node).trimmed
    }
    
    
    
    override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
        if node.macroName.text == WithSpecializedGenericsMacro.replaceMacroName {
            guard node.arguments.count > 1 else { return "" }
            guard let replacingExpr = node.arguments[1].expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue else { return "" }
            return super.visit(ExprSyntax(stringLiteral: replacingExpr)).trimmed
        }
        else {
            return super.visit(node.trimmed).trimmed
        }
        
    }
}






private extension InlinedGenericsRewriter {
    
    func transformGenericArgumentClause(clause: inout GenericArgumentClauseSyntax) {
        if clause.arguments.count != parameter.rightParameterList.count { return }
        
        var newArgs = [GenericArgumentSyntax]()
        
        // TODO: Checkname
        
        var i = 0
        var j = 0
        for arg in clause.arguments {
            if  j < replacements.count  && replacements[j].index == i {
                // jump
                j += 1
            }
            else {
                newArgs.append(arg)
            }
            i += 1
        }
        
        
        clause.arguments = .init {
            for arg in newArgs {
                arg
            }
        }
        
        if clause.arguments.count == 0 {
            clause.leftAngle = ""
            clause.rightAngle = ""
        }
        else {
            let i = clause.arguments.indices.index(before: clause.arguments.indices.endIndex)
            clause.arguments[i].trailingComma = nil
        }
    }
    
    
    func transformGenericParameterClause(clause: inout GenericParameterClauseSyntax) {
        if clause.parameters.count != parameter.rightParameterList.count { return }
        
        
        var newArgs = [GenericParameterSyntax]()
        
        
        // TODO: Checkname
        
        var i = 0
        var j = 0
        for arg in clause.parameters {
            
            if  j < replacements.count  && replacements[j].index == i {
                // jump
                j += 1
            }
            else {
                newArgs.append(arg)
            }
            i += 1
        }
        
        
        clause.parameters = .init {
            for arg in newArgs {
                arg
            }
        }
        
        if clause.parameters.count == 0 {
            clause.leftAngle = ""
            clause.rightAngle = ""
        }
        else {
            let i = clause.parameters.indices.index(before: clause.parameters.indices.endIndex)
            clause.parameters[i].trailingComma = nil
        }
        
        clause = clause.trimmed
        
        
//        if let indexToRemove = parameter.oldGenericParameterIndexToRemove {
//            clause.parameters.remove(at: indexToRemove)
//        }
//        
//        if clause.parameters.count == 0 {
//            clause.leftAngle = ""
//            clause.rightAngle = ""
//        }
//        else {
//            let i = clause.parameters.indices.index(before: clause.parameters.indices.endIndex)
//            clause.parameters[i].trailingComma = nil
//        }
    }
    
    func rewriteRequirement(_ syntax: GenericRequirementSyntax) -> GenericRequirementSyntax? {
        switch syntax.requirement {
        case .conformanceRequirement(var conformance):
            let refencingAnyIdentifierToReplace = replacementsMapping.contains { repMap in
                guard repMap.shouldReplaceOrRemove else { return false }
                
                /// has new name, should remove, so return nil if its referenced
                let identifier = repMap.oldName
                
                return conformance.leftType.isReferencing(typeIdentifier: identifier)
                || conformance.rightType.isReferencing(typeIdentifier: identifier)
            }
            if !refencingAnyIdentifierToReplace {
                return syntax
            }
            else {
                var isReferencingKeptGenericParam = false
                /// type or base type is referencing remaining params => replace removed with new concrete type
                for keptGenericParam in (replacementsMapping.filter { !$0.shouldReplaceOrRemove }) {
                    if conformance.leftType.isReferencing(typeIdentifier: keptGenericParam.oldName)
                    || conformance.rightType.isReferencing(typeIdentifier: keptGenericParam.oldName){
                        isReferencingKeptGenericParam = true
                        break
                        //sameType.rightType = sameType.rightType.withModifiedReference(from: keptGenericParam.oldName, to: keptGenericParam.newName!)
                    }
                }
                
                if isReferencingKeptGenericParam {
                    for replacedGenericParam in (replacementsMapping.filter { $0.shouldReplaceOrRemove }) {
                        conformance.rightType = conformance.rightType.withModifiedReference(from: replacedGenericParam.oldName, to: replacedGenericParam.newName!)
                        conformance.leftType = conformance.leftType.withModifiedReference(from: replacedGenericParam.oldName, to: replacedGenericParam.newName!)
                    }
                    return GenericRequirementSyntax(requirement: .conformanceRequirement(conformance.trimmed), trailingComma: syntax.trailingComma)
                }
                
                return nil
            }
        case .sameTypeRequirement(var sameType):
            
            let refencingAnyIdentifierToReplace = replacementsMapping.contains { repMap in
                guard repMap.shouldReplaceOrRemove else { return false }
                
                /// has new name, should remove, so return nil if its referenced
                let identifier = repMap.oldName
                
                return sameType.leftType.isReferencing(typeIdentifier: identifier)
                || sameType.rightType.isReferencing(typeIdentifier: identifier)
            }
            if !refencingAnyIdentifierToReplace {
                return syntax
            }
            else {
                var isReferencingKeptGenericParam = false
                /// type or base type is referencing remaining params => replace removed with new concrete type
                for keptGenericParam in (replacementsMapping.filter { !$0.shouldReplaceOrRemove }) {
                    if sameType.leftType.isReferencing(typeIdentifier: keptGenericParam.oldName)
                    || sameType.rightType.isReferencing(typeIdentifier: keptGenericParam.oldName){
                        isReferencingKeptGenericParam = true
                        break
                        //sameType.rightType = sameType.rightType.withModifiedReference(from: keptGenericParam.oldName, to: keptGenericParam.newName!)
                    }
                }
                
                if isReferencingKeptGenericParam {
                    for replacedGenericParam in (replacementsMapping.filter { $0.shouldReplaceOrRemove }) {
                        sameType.rightType = sameType.rightType.withModifiedReference(from: replacedGenericParam.oldName, to: replacedGenericParam.newName!)
                        sameType.leftType = sameType.leftType.withModifiedReference(from: replacedGenericParam.oldName, to: replacedGenericParam.newName!)
                    }
                    return GenericRequirementSyntax(requirement: .sameTypeRequirement(sameType.trimmed), trailingComma: syntax.trailingComma)
                }
                
                return nil
            }
            
        case .layoutRequirement(_):
            return syntax
        }
        
        
        
    }
    
    
    func transformGenericWhereClause(clause: inout GenericWhereClauseSyntax) {
        
        
//        let identifierToReplace = replacements.map { self.originalRightParameterNames[$0.index] }
//        let identifierToHold = self.originalRightParameterNames.filter { !identifierToReplace.contains($0) }
        
        
//        let otherGenericIdentifiers = parameter.oldGenericParameterList.map { p in
//            p.name.text
//        }.filter {
//            $0 != identifier
//        }
        
        var newRequirements: [GenericRequirementListSyntax.Element] = []
        
        for requirement in clause.requirements {
            if let rewritten = rewriteRequirement(requirement) {
                newRequirements.append(rewritten)
            }
//            switch requirement.requirement {
//            case .conformanceRequirement(let conformanceRequirement):
//
//                // not referencing any identifierToReplace
//                let refencingAnyIdentifierToReplace = identifierToReplace.contains { identifier in
//                    conformanceRequirement.leftType.isReferencing(typeIdentifier: identifier)
//                    || conformanceRequirement.rightType.isReferencing(typeIdentifier: identifier)
//                }
//                if !refencingAnyIdentifierToReplace {
//                    newRequirements.append(requirement)
//                }
//                
//            case .sameTypeRequirement(var sameTypeRequirement):
//                
//                let refencingAnyIdentifierToReplace = identifierToReplace.contains { identifier in
//                    sameTypeRequirement.leftType.isReferencing(typeIdentifier: identifier)
//                    || sameTypeRequirement.rightType.isReferencing(typeIdentifier: identifier)
//                }
//                if !refencingAnyIdentifierToReplace {
//                    newRequirements.append(requirement)
//                }
//                else {
//                    /// if met any type referencing remaining generic params, replace the removed with concrete type
//                    ///
//                    
////                    for i in originalRightParameterNames.indices {
////                        let gi = originalRightParameterNames[i]
////                        if identifierToReplace.contains(gi) { continue }
////                        
////                        if sameTypeRequirement.leftType.isReferencing(typeIdentifier: gi) {
////
////                            sameTypeRequirement.rightType = sameTypeRequirement.rightType.withModifiedReference(from: identifier, to: parameter.to.baseName.text)
////                            
////                            newRequirements.append(
////                                GenericRequirementSyntax(requirement: .sameTypeRequirement(sameTypeRequirement), trailingComma: requirement.trailingComma)
////                            )
////                        }
////                        else if sameTypeRequirement.rightType.isReferencing(typeIdentifier: gi){
////
////                            sameTypeRequirement.leftType = sameTypeRequirement.leftType.withModifiedReference(from: identifier, to: parameter.to.baseName.text)
////                            newRequirements.append(
////                                GenericRequirementSyntax(requirement: .sameTypeRequirement(sameTypeRequirement), trailingComma: requirement.trailingComma)
////                            )
////                        }
////                    }
//                    
//                }
//            case .layoutRequirement(_):
//                newRequirements.append(requirement)
//            }
        }
        
        clause.requirements.removeSubrange(clause.requirements.indices.startIndex..<clause.requirements.indices.endIndex)
        assert(clause.requirements.isEmpty)
        
        
        if newRequirements.count>0 && self.parameter.requirements.count > 0 {
            newRequirements[newRequirements.count - 1].trailingComma = ","
        }
        
        for nr in newRequirements {
            clause.requirements.append(nr)
        }
        
        
        
        for newlyAddedInTypealias in self.parameter.requirements {
            clause.requirements.append(newlyAddedInTypealias)
        }
        
        if clause.requirements.count == 0 {
            clause.whereKeyword = ""
        }
        else {
            let i = clause.requirements.indices.index(before: clause.requirements.indices.endIndex)
            clause.requirements[i].trailingComma = nil
        }
        clause = clause.trimmed
    }
    
    
    
}
