//
//  File.swift
//  
//
//  Created by li3zhen1 on 10/24/23.
//

import Foundation

import SwiftSyntax
import SwiftParser


public struct MappingEntry {
    public let name: String
    public let typeDicts: [(String, String)]
}


public enum MappingEntryError: Error {
    case specializedNameNotSpecified
    case specializedTypeMappingsNotFound
    case nonInfixExprSyntaxFoundInMapping
}

public extension Array where Element == MappingEntry {
    func formatted() -> String {
        return map { ele in
            ele.formatted()
        }.joined(separator: "\n")
    }
}


public extension MappingEntry {
    
    func formatted() -> String {
        return """
        \(name) {
            \(typeDicts.map {"\($0.0) = \($0.1)"}.joined(separator: "\n    "))
        }
        """
    }
    
    static func parse(_ source: String) throws -> [MappingEntry]  {
        let sourceFileSyntax = Parser.parse(source: source)
        let codeBlockItems = sourceFileSyntax.statements
        var results: [MappingEntry] = []
        for item in codeBlockItems {
            guard let funcCall = item.item.as(FunctionCallExprSyntax.self) else {
                throw MappingEntryError.specializedNameNotSpecified
            }
            guard let declRef = funcCall.calledExpression.as(DeclReferenceExprSyntax.self) else {
                throw MappingEntryError.specializedNameNotSpecified
            }
            guard let trailingClosure = funcCall.trailingClosure?.as(ClosureExprSyntax.self) else {
                throw MappingEntryError.specializedTypeMappingsNotFound
            }
            var mapping: [(String, String)] = []
            for statement in trailingClosure.statements {
                guard let seqExpr = statement.item.as(SequenceExprSyntax.self) else {
                    throw MappingEntryError.nonInfixExprSyntaxFoundInMapping
                }
                
                var i = 0
                var leftName: String? = nil
                var rightName: String? = nil
                for ele in seqExpr.elements {
                    switch i {
                    case 0:
                        leftName = ele.trimmedDescription
                    case 1:
                        if ele.trimmedDescription != "=" {
                            throw MappingEntryError.nonInfixExprSyntaxFoundInMapping
                        }
                    case 2:
                        rightName = ele.trimmedDescription
                    default:
                        throw MappingEntryError.nonInfixExprSyntaxFoundInMapping
                    }
                    i += 1
                }
                guard let leftName, let rightName else { throw MappingEntryError.nonInfixExprSyntaxFoundInMapping }
                mapping.append((leftName, rightName))
//                mapping[infixOpExpr.leftOperand.trimmedDescription] = infixOpExpr.rightOperand.trimmedDescription
            }
            results.append(.init(name: declRef.trimmedDescription, typeDicts: mapping))
        }
        return results
    }
}
