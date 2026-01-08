//
//  IndentUtils.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Foundation

enum IndentUtils {
    private static let indent = "    " // 4 spaces
    static func indentLines(_ text: String, level: Int) -> String {
        let prefix = String(repeating: indent, count: level)
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { prefix + $0 }
            .joined(separator: "\n")
    }
}
