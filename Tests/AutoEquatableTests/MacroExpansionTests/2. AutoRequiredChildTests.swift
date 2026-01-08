//
//  AutoRequiredChildTests.swift
//  AutoEquatable
//
//  Created by 김동현 on 1/8/26.
//

import Testing
import AutoEquatable

@Suite("AutoRequiredChild")
struct AutoRequiredChildTests {

    // MARK: - Fixture Types

    struct Profile {
        let email: String
        let age: Int
    }

    @AutoEquatable
    struct User {
        let id: Int

        // ✅ profile 전체를 비교하지 않고,
        //    profile.email만 비교하도록 지정
        @AutoRequiredChild(\Profile.email)
        let profile: Profile
    }

    // MARK: - Tests
    @Test("child keyPath 값(email)이 같으면 다른 값(age)이 달라도 == 는 true")
    func child_same_email_is_equal() {
        let a = User(
            id: 1,
            profile: .init(email: "a@test.com", age: 20)
        )

        let b = User(
            id: 1,
            profile: .init(email: "a@test.com", age: 99)
        )

        #expect(a == b)
    }

    @Test("child keyPath 값(email)이 다르면 == 는 false")
    func child_different_email_is_not_equal() {
        let a = User(
            id: 1,
            profile: .init(email: "a@test.com", age: 20)
        )

        let b = User(
            id: 1,
            profile: .init(email: "b@test.com", age: 20)
        )

        #expect(a != b)
    }

    @Test("다른 stored property(id)가 다르면 false")
    func non_child_property_difference_is_not_equal() {
        let a = User(
            id: 1,
            profile: .init(email: "a@test.com", age: 20)
        )

        let b = User(
            id: 2,
            profile: .init(email: "a@test.com", age: 20)
        )

        #expect(a != b)
    }
}
