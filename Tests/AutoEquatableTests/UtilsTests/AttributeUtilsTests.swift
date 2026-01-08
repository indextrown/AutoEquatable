//
//  AttributeUtilsTests.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Testing
import SwiftSyntax
@testable import AutoEquatableMacros

@Suite("AttributeUtils 테스트")
struct AttributeUtilsTests {

    @Test("hasAttribute: Attribute가 있으면 true")
    func hasAttribute_true() throws {
        let source = """
        struct User {
            @AutoIgnored
            var name: String
        }
        """

        let varDecl = try TestSyntaxBuilder.parseFirstVariable(source)

        let result = AttributeUtils.hasAttribute(
            in: varDecl,
            named: "AutoIgnored"
        )

        #expect(result == true)
    }

    @Test("hasAttribute: Attribute가 없으면 false")
    func hasAttribute_false() throws {
        let source = """
        struct User {
            var name: String
        }
        """

        let varDecl = try TestSyntaxBuilder.parseFirstVariable(source)

        let result = AttributeUtils.hasAttribute(
            in: varDecl,
            named: "AutoIgnored"
        )

        #expect(result == false)
    }

    @Test("findAttribute: 지정한 Attribute를 찾는다")
    func findAttribute_returnsAttribute() throws {
        let source = """
        struct User {
            @AutoPriority(10)
            var age: Int
        }
        """

        let varDecl = try TestSyntaxBuilder.parseFirstVariable(source)

        let attribute = AttributeUtils.findAttribute(
            in: varDecl,
            named: "AutoPriority"
        )

        #expect(attribute != nil)
    }

    @Test("extractIntArgument: Int 인자를 정상적으로 추출한다")
    func extractIntArgument_success() throws {
        let source = """
        struct User {
            @AutoPriority(42)
            var score: Int
        }
        """

        let varDecl = try TestSyntaxBuilder.parseFirstVariable(source)
        let attribute = AttributeUtils.findAttribute(
            in: varDecl,
            named: "AutoPriority"
        )!

        let value = AttributeUtils.extractIntArgument(from: attribute)

        #expect(value == 42)
    }

    @Test("extractIntArgument: 인자가 없으면 nil")
    func extractIntArgument_nil_whenNoArgument() throws {
        let source = """
        struct User {
            @AutoPriority
            var score: Int
        }
        """

        let varDecl = try TestSyntaxBuilder.parseFirstVariable(source)
        let attribute = AttributeUtils.findAttribute(
            in: varDecl,
            named: "AutoPriority"
        )!

        let value = AttributeUtils.extractIntArgument(from: attribute)

        #expect(value == nil)
    }
}
