//
//  KeyPathUtilsTests.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Testing
import SwiftSyntax
@testable import AutoEquatableMacros

@Suite("KeyPathUtils 테스트")
struct KeyPathUtilsTests {

    @Test("KeyPath \\ .profile.name → \"profile.name\"")
    func extractKeyPathString_simple() throws {
        let source = """
        struct User {
            @AutoRequiredChild(\\.profile.name)
            var child: String
        }
        """

        let varDecl = try TestSyntaxBuilder.parseFirstVariable(source)
        let attribute = AttributeUtils.findAttribute(
            in: varDecl,
            named: "AutoRequiredChild"
        )!

        let keyPath = KeyPathUtils.extractKeyPathString(from: attribute)

        #expect(keyPath == "profile.name")
    }

    @Test("KeyPath가 아니면 nil 반환")
    func extractKeyPathString_nil_whenNotKeyPath() throws {
        let source = """
        struct User {
            @AutoRequiredChild(123)
            var child: String
        }
        """

        let varDecl = try TestSyntaxBuilder.parseFirstVariable(source)
        let attribute = AttributeUtils.findAttribute(
            in: varDecl,
            named: "AutoRequiredChild"
        )!

        let keyPath = KeyPathUtils.extractKeyPathString(from: attribute)

        #expect(keyPath == nil)
    }
}
