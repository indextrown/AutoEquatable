//
//  TestSyntaxBuilder.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import SwiftSyntax
import SwiftParser

enum TestSyntaxBuilder {
    
    // 테스트에서 Swift 코드 문자열을 AST로 바꿔주는 유틸
    /// struct 안의 첫 번째 변수 선언을 파싱해서 반환
    static func parseFirstVariable(
        _ source: String
    ) throws -> VariableDeclSyntax {
        
        let sourceFile = Parser.parse(source: source)
        
        guard
            let structDecl = sourceFile.statements
                .first?
                .item
                .as(StructDeclSyntax.self),
            
                let member = structDecl.memberBlock.members.first,
            
                let varDecl = member.decl
                .as(VariableDeclSyntax.self)
        else {
            fatalError("VariableDeclSyntax 파싱 실패")
        }
        
        return varDecl
    }
}
