//
//  AutoPriorityMacro.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct AutoPriorityMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingPeersOf declaration: some DeclSyntaxProtocol,
                                 in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
