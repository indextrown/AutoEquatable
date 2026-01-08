//
//  AutoPriorityTests.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Testing
import AutoEquatable

@Suite("AutoPriority")
struct AutoPriorityTests {

    @AutoEquatable
    struct User {
        @AutoPriority(1)
        let id: Int

        @AutoPriority(0)
        let name: String
    }

    @Test("우선순위가 낮은 숫자부터 비교된다 (기능상 결과는 동일)")
    func priority_order_does_not_change_semantics() {
        let a = User(id: 1, name: "Alice")
        let b = User(id: 1, name: "Bob")

        #expect(a != b)
    }
}
