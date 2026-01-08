//
//  File.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

/*
 func basicEquatable_success() {
     assertMacroExpansion(
         SOURCE,
         expandedSource: EXPECTED,
         macros: ...
     )
 }

 SOURCE 코드를 컴파일러에게 제공하면
 EXPECTED 코드가 만들어져야 한다
 
 1. source 문자열을 SwiftSyntax로 파싱
 2. @AutoEquatable 매크로를 실제로 실행
 3. 매크로 확장 결과 코드 전체를 문자열로 생성
 4. 그 결과를 expandedSource와 문자열 비교
 */

import Testing
import AutoEquatable   // 매크로가 적용된 모듈

@Suite("AutoEquatable 기본 동작")
struct AutoEquatableBasicTests {

    @AutoEquatable
    struct User {
        let id: Int
        let name: String
    }

    @Test("모든 stored property가 같으면 == 는 true")
    func equatable_success_whenAllPropertiesEqual() {
        let a = User(id: 1, name: "Alice")
        let b = User(id: 1, name: "Alice")

        #expect(a == b)
    }

    @Test("하나라도 다르면 == 는 false")
    func equatable_failure_whenAnyPropertyDifferent() {
        let a = User(id: 1, name: "Alice")
        let b = User(id: 1, name: "Bob")

        #expect(a != b)
    }
}
