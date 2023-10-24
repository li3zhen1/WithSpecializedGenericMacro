//
//  File.swift
//  
//
//  Created by li3zhen1 on 10/23/23.
//

import SwiftSyntax
import SwiftSyntaxBuilder


struct WithSpecializedGenericMacroParameter {
    let oldName: String
    let oldGenericParameterList: GenericParameterListSyntax
    
    let newName: String
    
    
    let from: String
    let to: DeclReferenceExprSyntax
    
}

extension WithSpecializedGenericMacroParameter {
    var oldGenericParameterIndexToRemove: GenericArgumentListSyntax.Index? {
        return oldGenericParameterList.firstIndex { param in

            return param.name.text == from
            
        }
    }
}


class SpecializeGenericRewriter: SyntaxRewriter {
    
    private func transformGenericArgumentClause(clause: inout GenericArgumentClauseSyntax) {
        precondition(clause.arguments.count == parameter.oldGenericParameterList.count)
        
        if let indexToRemove = parameter.oldGenericParameterIndexToRemove {
            clause.arguments.remove(at: indexToRemove)
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
    
    
    private func transformGenericParameterClause(clause: inout GenericParameterClauseSyntax) {
        precondition(clause.parameters.count == parameter.oldGenericParameterList.count)
        
        if let indexToRemove = parameter.oldGenericParameterIndexToRemove {
            clause.parameters.remove(at: indexToRemove)
        }
        
        if clause.parameters.count == 0 {
            clause.leftAngle = ""
            clause.rightAngle = ""
        }
        else {
            let i = clause.parameters.indices.index(before: clause.parameters.indices.endIndex)
            clause.parameters[i].trailingComma = nil
        }
    }
    
    
    private func transformGenericWhereClause(clause: inout GenericWhereClauseSyntax) {
        
        
        
        let identifier = parameter.from
        
        let otherGenericIdentifiers = parameter.oldGenericParameterList.map { p in
            p.name.text
        }.filter {
            $0 != identifier
        }
        
        var newRequirements: [GenericRequirementListSyntax.Element] = []
        
        for requirement in clause.requirements {
            switch requirement.requirement {
            case .conformanceRequirement(let conformanceRequirement):
                if (!conformanceRequirement.leftType.isReferencing(identifier: identifier) && !conformanceRequirement.rightType.isReferencing(identifier: identifier)) {
                    newRequirements.append(requirement)
                }
            case .sameTypeRequirement(var sameTypeRequirement):
                if !sameTypeRequirement.leftType.isReferencing(identifier: identifier) && !sameTypeRequirement.rightType.isReferencing(identifier: identifier) {
                    newRequirements.append(requirement)
                }
                else {
                    
                    for gi in otherGenericIdentifiers {
                        if sameTypeRequirement.leftType.isReferencing(identifier: gi) {

                            sameTypeRequirement.rightType = sameTypeRequirement.rightType.modifyReference(from: identifier, to: parameter.to.baseName.text)
                            
                            newRequirements.append(
                                GenericRequirementSyntax(requirement: .sameTypeRequirement(sameTypeRequirement), trailingComma: requirement.trailingComma)
                            )
                        }
                        else if sameTypeRequirement.rightType.isReferencing(identifier: gi){

                            sameTypeRequirement.leftType = sameTypeRequirement.leftType.modifyReference(from: identifier, to: parameter.to.baseName.text)
                            newRequirements.append(
                                GenericRequirementSyntax(requirement: .sameTypeRequirement(sameTypeRequirement), trailingComma: requirement.trailingComma)
                            )
                        }
                    }
                    
                }
            case .layoutRequirement(_):
                newRequirements.append(requirement)
            }
        }
        
        clause.requirements.removeSubrange(clause.requirements.indices.startIndex..<clause.requirements.indices.endIndex)
        assert(clause.requirements.isEmpty)
        for nr in newRequirements {
            clause.requirements.append(nr)
        }
        
        
        if clause.requirements.count == 0 {
            clause.whereKeyword = ""
        }
        else {
            let i = clause.requirements.indices.index(before: clause.requirements.indices.endIndex)
            clause.requirements[i].trailingComma = nil
        }
    }
    
    
    let parameter: WithSpecializedGenericMacroParameter
    
    init(parameter: WithSpecializedGenericMacroParameter) {
        self.parameter = parameter
    }
    
    
    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        guard node.name.text == parameter.oldName else { return node.as(TypeSyntax.self)! }
        var node = node
        if node.genericArgumentClause != nil {
            transformGenericArgumentClause(clause: &node.genericArgumentClause!)
        }
        node.name = TokenSyntax(stringLiteral: parameter.newName)
        return node.as(TypeSyntax.self)!
    }
    
    
    override func visit(_ node: GenericSpecializationExprSyntax) -> ExprSyntax {
        guard var declRef = node.expression.as(DeclReferenceExprSyntax.self),
              declRef.baseName.text == parameter.oldName else { return node.as(ExprSyntax.self)! }
        
        var node = node
        transformGenericArgumentClause(clause: &node.genericArgumentClause)
        declRef.baseName = TokenSyntax(stringLiteral: parameter.newName)
        node.expression = declRef.as(ExprSyntax.self)!
        
        return node.as(ExprSyntax.self)!
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
//        guard let declRef = node.expression.as(DeclReferenceExprSyntax.self),
//              declRef.baseName.text == parameter.oldName else { return node.as(ExprSyntax.self)! }
        
        var node = node
        
        if node.baseName.text == parameter.oldName {
            node.baseName = TokenSyntax(stringLiteral: parameter.newName)
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
}
