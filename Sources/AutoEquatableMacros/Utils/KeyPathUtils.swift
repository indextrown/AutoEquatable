//
//  File.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import SwiftSyntax

enum KeyPathUtils {
    /// Attribute의 첫 번째 인자를 KeyPath 문자열로 추출합니다.
    ///
    /// 예:
    /// ```swift
    /// @AutoRequiredChild(\.user.profile.name)
    /// ```
    ///
    /// → `"user.profile.name"`
    static func extractKeyPathString(from attribute: AttributeSyntax
    ) -> String? {
        
        guard let args = attribute.arguments?.as(LabeledExprListSyntax.self),
              let first = args.first
        else { return nil }
        
        guard let keyPathExpr = first.expression.as(KeyPathExprSyntax.self)
        else { return nil }
        
        let parts: [String] = keyPathExpr.components.compactMap { comp in
            comp.component
                .as(KeyPathPropertyComponentSyntax.self)?
                .declName
                .baseName
                .text
        }
        
        guard !parts.isEmpty else { return nil }
                return parts.joined(separator: ".")
    }
}
