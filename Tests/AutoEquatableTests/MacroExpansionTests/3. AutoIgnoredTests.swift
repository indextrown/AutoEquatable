//
//  AutoIgnoredTests.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Testing
import AutoEquatable

@Suite("AutoIgnored")
struct AutoIgnoredTests {

    @AutoEquatable
    struct User {
        let id: Int

        @AutoIgnored
        let cacheKey: String
    }

    @Test("AutoIgnored 프로퍼티는 비교에서 제외된다")
    func ignored_property_is_not_compared() {
        let a = User(id: 1, cacheKey: "A")
        let b = User(id: 1, cacheKey: "B")

        #expect(a == b)
    }

    @Test("ignored가 아닌 프로퍼티가 다르면 == false")
    func non_ignored_difference_is_not_equal() {
        let a = User(id: 1, cacheKey: "A")
        let b = User(id: 2, cacheKey: "A")

        #expect(a != b)
    }
}
