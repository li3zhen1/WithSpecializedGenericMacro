//
//  File.swift
//  
//
//  Created by li3zhen1 on 10/25/23.
//

import SwiftSyntax





protocol ConformanceOrSameTypeRequirementSyntaxProtocol: SyntaxProtocol {
    var leftType: TypeSyntax { get }
    var rightType: TypeSyntax { get }
}


extension SameTypeRequirementSyntax: ConformanceOrSameTypeRequirementSyntaxProtocol {}

extension ConformanceRequirementSyntax: ConformanceOrSameTypeRequirementSyntaxProtocol {}







protocol ClassStructOrProtocolExtensionSyntax: DeclSyntaxProtocol {
    var genericWhereClause: GenericWhereClauseSyntax? {get set }
    var memberBlock: MemberBlockSyntax {get set}
    var attributes: AttributeListSyntax {get set}
}


protocol ClassOrStructDeclSyntax: ClassStructOrProtocolExtensionSyntax {
    var genericParameterClause: GenericParameterClauseSyntax? { get set }
    var name: TokenSyntax {get set}
}

extension ClassDeclSyntax: ClassOrStructDeclSyntax { }
extension StructDeclSyntax: ClassOrStructDeclSyntax { }
extension ProtocolDeclSyntax: ClassStructOrProtocolExtensionSyntax { }
extension ExtensionDeclSyntax: ClassStructOrProtocolExtensionSyntax { }






extension TypeSyntax {
    func isReferencing(typeIdentifier identifier: String) -> Bool {
        if let self = self.as(IdentifierTypeSyntax.self) {
            return self.name.text == identifier
        }
        else if let self = self.as(MemberTypeSyntax.self) {
            return self.baseType.isReferencing(typeIdentifier: identifier)
        }
        return false
    }
    
    func withModifiedReference(from identifier: String, to: String) -> TypeSyntax {
        if var self = self.as(IdentifierTypeSyntax.self) {
            if self.name.text == identifier {
                self.name = TokenSyntax(stringLiteral: to)
            }
            return self.as(TypeSyntax.self)!
        }
        else if var self = self.as(MemberTypeSyntax.self) {
            self.baseType = self.baseType.withModifiedReference(from: identifier, to: to)
            return self.as(TypeSyntax.self)!
        }
        return self
    }
}



extension SyntaxCollection {
    subscript (_ i: Int) -> Element {
        get {
            return self[self.index(self.startIndex, offsetBy:i)]
        }
        set {
            self[self.index(self.startIndex, offsetBy:i)] = newValue
        }
    }
    
    mutating func remove(atIndex i: Int) -> Element {
        return self.remove(at: self.index(self.startIndex, offsetBy:i))
    }
}
