//
//  AutoRequiredTests.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Testing
import AutoEquatable   // 매크로가 적용된 모듈

@Suite("@AutoRequired 동작")
struct AutoRequiredTests {

    @AutoEquatable
    struct User {
        @AutoRequired
        let id: Int
        
        @AutoIgnored
        let name: String
    }

    @Test("AutoRequired 프로퍼티가 같으면 == true")
    func required_equal() {
        let a = User(id: 1, name: "A")
        let b = User(id: 1, name: "B")

        #expect(a == b)
    }

    @Test("AutoRequired 프로퍼티가 다르면 == false")
    func required_not_equal() {
        let a = User(id: 1, name: "A")
        let b = User(id: 2, name: "A")

        #expect(a != b)
    }
}

