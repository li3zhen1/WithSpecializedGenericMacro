//
//  File.swift
//  
//
//  Created by li3zhen1 on 10/25/23.
//

import SwiftSyntax
import SwiftParser


public struct InlinedTypealiasParameter {
    let declModifiers: [String]
    
    let leftName: String
    let leftParameterList: [String]
    
    let rightName: String
    let rightParameterList: [String]
    
    let requirements: [GenericRequirementSyntax]
}

public enum InlineTypealiasParameterError: Error {
    case unexpectedSyntax
    case unexpectedRightValueInTypealiasSyntax(String)
    case failedToMatchTypeIdentifier(String)
}



public extension InlinedTypealiasParameter {
    struct GenericParameterMapping {
        let index: Int
        let newName: String
    }
    
    
    func getMapping() throws -> [GenericParameterMapping] {
        var rightGenericParamLookup = [String:(Int, Bool)]()
        
        for i in rightParameterList.indices {
            rightGenericParamLookup[rightParameterList[i]] = (i, false)
        }
        
        for lp in leftParameterList {
            if rightGenericParamLookup[lp] != nil {
                rightGenericParamLookup[lp]!.1 = true
            }
            else {
                throw InlineTypealiasParameterError.failedToMatchTypeIdentifier(lp)
            }
        }
        
        return rightGenericParamLookup.compactMap { entry in
            if entry.value.1 { return nil }
            else {
                return GenericParameterMapping(index: entry.value.0, newName: entry.key)
            }
        }
    }
}


public extension InlinedTypealiasParameter {
    
    static func parseFromSwiftSource(_ source: String) throws -> [Self] {
        let sourceFileSyntax = Parser.parse(source: source)
        let codeBlockItems = sourceFileSyntax.statements
        var results: [InlinedTypealiasParameter] = []
        for item in codeBlockItems {
            guard let typealiasDecl = item.item.as(TypeAliasDeclSyntax.self) else { throw InlineTypealiasParameterError.unexpectedSyntax }
            let declModifiers = typealiasDecl.modifiers.map { $0.trimmedDescription }
            let specializedName = typealiasDecl.name.trimmedDescription
            
            // TODO: Colon
            let leftGenericParams = typealiasDecl.genericParameterClause?.parameters.map {
                $0.name.trimmedDescription
            } ?? []
            
            guard let rightIdentifierType = typealiasDecl.initializer.value.as(IdentifierTypeSyntax.self) else { throw InlineTypealiasParameterError.unexpectedRightValueInTypealiasSyntax(typealiasDecl.initializer.value.description) }
            
            let originalName = rightIdentifierType.name.trimmedDescription
            
            let rightGenericParams = rightIdentifierType.genericArgumentClause?.arguments.compactMap { arg in
                arg.argument.as(IdentifierTypeSyntax.self)?.name.text
            } ?? []
            
            let rightWhereClause = typealiasDecl.genericWhereClause?.requirements.map {
                $0
            } ?? []
            
            
            
            results.append(.init(declModifiers: declModifiers, leftName: specializedName, leftParameterList: leftGenericParams, rightName: originalName, rightParameterList: rightGenericParams, requirements: rightWhereClause))
        }
        
        return results
    }
}
