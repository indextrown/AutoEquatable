//
//  File.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/13/26.
//

import Testing
import AutoEquatable

@Suite("Function / Closure filtering behavior")
struct FunctionTypeFilteringTests {

    // MARK: - 1. 명시적 함수 타입 (✅ 현재 구현에서 정상 통과해야 함)
    @AutoEquatable
    struct ExplicitFunctionUser {
        let id: Int
        let action: () -> Void
    }

    @Test("명시적 함수 타입 프로퍼티는 자동 제외된다")
    func explicit_function_type_is_ignored() {
        let a = ExplicitFunctionUser(id: 1, action: { })
        let b = ExplicitFunctionUser(id: 1, action: { })

        #expect(a == b)
    }

    // MARK: - 2. 타입 어노테이션 없는 클로저 (✅ 현재 구현에서 정상 통과해야 함)
    @AutoEquatable
    struct ClosureLiteralUser {
        let id: Int
        let onTap = { print("tap") }
    }

    @Test("타입 어노테이션 없는 클로저 리터럴은 자동 제외된다")
    func closure_literal_is_ignored() {
        let a = ClosureLiteralUser(id: 1)
        let b = ClosureLiteralUser(id: 1)

        #expect(a == b)
    }

    // MARK: - 3. Optional 함수 타입 (✅ 현재 구현에서 정상 통과해야 함)
    @AutoEquatable
    struct OptionalFunctionUser {
        let id: Int
        let handler: (() -> Void)?
    }

    @Test("Optional 함수 타입은 자동 제외된다")
    func optional_function_type_is_ignored() {
        let a = OptionalFunctionUser(id: 1, handler: nil)
        let b = OptionalFunctionUser(id: 1, handler: nil)

        #expect(a == b)
    }

    // MARK: - 4. Dictionary value에 함수 타입 (✅ 현재 구현에서 정상 통과해야 함)
    @AutoEquatable
    struct DictionaryFunctionUser {
        let id: Int
        let handlers: [String: () -> Void]
    }

    @Test("Dictionary value에 포함된 함수 타입은 자동 제외된다")
    func dictionary_function_type_is_ignored() {
        let a = DictionaryFunctionUser(id: 1, handlers: [:])
        let b = DictionaryFunctionUser(id: 1, handlers: [:])

        #expect(a == b)
    }

    // MARK: - 5. Tuple 내부 함수 타입 (✅ 현재 구현에서 정상 통과해야 함)
    @AutoEquatable
    struct TupleFunctionUser {
        let id: Int
        let payload: (Int, () -> Void)
    }

    @Test("Tuple 내부에 포함된 함수 타입은 자동 제외된다")
    func tuple_function_type_is_ignored() {
        let a = TupleFunctionUser(id: 1, payload: (1, { }))
        let b = TupleFunctionUser(id: 1, payload: (1, { }))

        #expect(a == b)
    }

    // MARK: - 6. Array 안의 함수 타입 (❌ 현재 구현의 한계)
    /*
    @AutoEquatable
    struct ArrayFunctionUser {
        let id: Int
        let callbacks: [() -> Void]
    }

    @Test("Array 안의 함수 타입은 현재 구현에서는 제외되지 않는다 (의도된 실패)")
    func array_function_type_currently_not_ignored() {
        let a = ArrayFunctionUser(id: 1, callbacks: [])
        let b = ArrayFunctionUser(id: 1, callbacks: [])

        // ❌ 현재 containsFunctionType는 ArrayTypeSyntax를 처리하지 않음
        #expect(a == b)
    }
     */

    // MARK: - 7. typealias로 감싼 함수 타입 (❌ 설계적 한계)
    /*
    typealias Completion = (Bool) -> Void

    @AutoEquatable
    struct TypealiasFunctionUser {
        let id: Int
        let completion: Completion
    }

    @Test("typealias로 감싼 함수 타입은 자동 감지 불가 (문서화 대상)")
    func typealias_function_is_not_detected() {
        let a = TypealiasFunctionUser(id: 1, completion: { _ in })
        let b = TypealiasFunctionUser(id: 1, completion: { _ in })

        // ❌ 매크로 단계에서 typealias 해석 불가
        #expect(a == b)
    }
     */
}
