//
//  AutoEquatablePlugin.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AutoEquatablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoEquatableMacro.self,
    ]
}
