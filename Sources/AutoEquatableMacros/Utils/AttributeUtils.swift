//
//  AttributeUtils
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import SwiftSyntax

enum AttributeUtils {
    
    /// `varDecl`(변수 선언)에 붙은 Attribute 중
    /// 이름이 `name`과 일치하는 Attribute를 하나 찾아 반환합니다.
    ///
    /// 이 메서드는 Swift 매크로 구현에서
    /// `@AutoIgnored`, `@AutoPriority(10)` 등과 같은
    /// 프로퍼티 레벨 Attribute를 분석하기 위해 사용됩니다.
    ///
    /// - Note:
    ///   현재는 `@AutoIgnored` 처럼 **단일 식별자 형태의 Attribute**
    ///   (`IdentifierTypeSyntax`)만 지원합니다.
    ///   (`@Module.AutoIgnored` 같은 Qualified Type은 추후 확장 가능)
    ///
    /// - Parameters:
    ///   - varDecl: Attribute를 검사할 대상 변수 선언 (`VariableDeclSyntax`)
    ///   - name:   찾고자 하는 Attribute의 이름 (예: `"AutoIgnored"`)
    ///
    /// - Returns:
    ///   이름이 `name`과 일치하는 `AttributeSyntax`를 반환하며,
    ///   해당 Attribute가 존재하지 않으면 `nil`을 반환합니다.
    static func findAttribute(in varDecl: VariableDeclSyntax,
                              named name: String
    ) -> AttributeSyntax? {
        let attrs = varDecl.attributes
        
        for attr in attrs {
            guard let attribute = attr.as(AttributeSyntax.self) else { continue }
            
            // @AutoIgnored / @AutoPriority 같은 단일 Identifier Attribute
            if let id = attribute.attributeName.as(IdentifierTypeSyntax.self),
               id.name.text == name {
                return attribute
            }
        }
        
        return nil
    }
    
    /// `varDecl`에 이름이 `name`인 Attribute가
    /// 하나라도 존재하는지 여부를 반환합니다.
    ///
    /// - Parameters:
    ///   - varDecl: 검사할 변수 선언
    ///   - name:    검사할 Attribute 이름
    ///
    /// - Returns:
    ///   해당 Attribute가 존재하면 `true`,
    ///   존재하지 않으면 `false`
    static func hasAttribute(in varDecl: VariableDeclSyntax,
                             named name: String
    ) -> Bool {
        return findAttribute(in: varDecl, named: name) != nil
    }
    
    /// Attribute의 첫 번째 인자를 정수(`Int`)로 추출합니다.
    ///
    /// 예:
    /// ```swift
    /// @AutoPriority(10)
    /// ```
    ///
    /// 위 Attribute에서 `10`을 추출합니다.
    ///
    /// - Note:
    ///   현재는 **첫 번째 인자가 정수 리터럴인 경우만** 지원합니다.
    ///
    /// - Parameter attribute: 인자를 추출할 `AttributeSyntax`
    /// - Returns:
    ///   정수 인자가 존재하면 `Int`,
    ///   존재하지 않거나 정수 리터럴이 아니면 `nil`
    static func extractIntArgument(from attribute: AttributeSyntax
    ) -> Int? {
        guard let args = attribute.arguments?.as(LabeledExprListSyntax.self),
              let first = args.first,
              let intLiteral = first.expression.as(IntegerLiteralExprSyntax.self)
                else { return nil }
        
        return Int(intLiteral.literal.text)
    }
}
