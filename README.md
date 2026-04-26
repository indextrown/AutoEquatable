# AutoEquatable

> `AutoEquatable`은 SwiftUI의 불필요한 View 재계산을 줄이기 위해
> 동등성 기준을 선언적으로 정의하고,
> `Equatable` 구현을 컴파일 타임에 자동 생성하는 Swift Macro입니다.

<!-- <img
  src="https://github.com/user-attachments/assets/48cc1dab-ad53-4e4a-aeeb-974e9e581cec"
  width="400"
/> -->

<img
  src="https://github.com/user-attachments/assets/3938e583-0fc4-4620-99b0-bf761e60a1ba"
  width="400"
/>

## Table of Contents

- [SwiftUI에서 왜 필요한가](#swiftui에서-왜-필요한가)
- [기존 해결 방식의 한계](#기존-해결-방식의-한계)
- [AutoEquatable이란](#autoequatable이란)
- [핵심 가치](#핵심-가치)
- [Features](#features)
- [How to Use](#how-to-use)
- [Annotations](#annotations)
- [Ordering Rule](#ordering-rule)
- [Closure Handling](#closure-handling)

## SwiftUI에서 왜 필요한가

SwiftUI에서는 하나의 셀만 변경되었는데도 의미 있는 변화가 없는 다른 View까지 다시 그려지는 상황이 자주 생깁니다.

- 이 문제는 SwiftUI diffing 과정에서 "이전 View와 새로운 View가 같은지" 판단할 기준이 명확하지 않을 때 발생합니다.
- SwiftUI는 View를 다시 그릴지 결정하기 위해 타입과 구조를 바탕으로 변경 여부를 추론합니다.
- 아래 코드는 그 과정을 설명하기 위한 개념적인 의사 코드입니다.

```swift
// SwiftUI diffing 과정 의사 코드
func shouldUpdateView<V: View>(_ oldView: V, _ newView: V) -> Bool {
    // 1. Equatable 타입이면 == 연산자 사용
    if V.self is Equatable.Type {
        return oldView != newView
    }

    // 2. 값 타입(struct)이면 재귀적으로 프로퍼티 비교
    if V.self is ValueType {
        return compareProperties(oldView, newView)
    }

    // 3. 참조 타입(class)이면 참조 동일성 비교
    if V.self is ReferenceType {
        return oldView !== newView
    }

    // 4. 클로저는 비교 불가능하므로 항상 다르다고 가정
    if containsClosures(V.self) {
        return true
    }
}
```

> 위 코드는 실제 SwiftUI 구현이 아니라, View diffing의 의사 결정 흐름을 설명하기 위한 개념적 예시입니다.

## 기존 해결 방식의 한계

보통은 아래 방식으로 문제를 해결합니다.

1. `EquatableView`를 사용하거나 View에 `Equatable`을 채택해 `==` 기준을 직접 정의
2. `.equatable()` modifier를 적용해 SwiftUI diffing 단계에 명시적으로 참여
3. `static func ==`를 수동 구현

이 방식은 분명 효과적이지만, 다음과 같은 단점이 있습니다.

- 코드가 장황해집니다.
- 비교 기준이 타입 정의와 분리됩니다.
- 수정할 때 실수하기 쉽고 유지보수 비용이 커집니다.

`AutoEquatable`은 이 문제를 선언적으로 해결하기 위해 만들어졌습니다. 비교 기준을 타입 정의에 가깝게 선언하고, SwiftUI diffing 과정에서 불필요한 `body` 재계산을 줄일 수 있도록 `Equatable` 구현을 컴파일 타임에 안전하게 생성합니다.

## AutoEquatable이란

`AutoEquatable`은 Swift Macro를 이용해 `Equatable` 구현을 자동 생성하면서도,
"무엇을 비교할지"와 "어떤 순서로 비교할지"를 어노테이션 기반 DSL로 명확하게 선언할 수 있게 해주는 라이브러리입니다.

## 핵심 가치

`@AutoEquatable`를 사용하면 SwiftUI에서 `.equatable()`을 더 안전하고, 짧고, 의도적으로 사용할 수 있습니다.

- 변경되지 않은 셀은 다시 그리지 않도록 돕습니다.
- 비교 기준을 타입 정의에서 명확하게 드러낼 수 있습니다.
- 실수하기 쉬운 `==` 구현을 컴파일 타임에 생성합니다.
- SwiftUI `List` 성능 최적화를 위한 가벼운 도구로 사용할 수 있습니다.

또한 Swift의 기본 `Equatable` 자동 합성이 가진 한계도 보완합니다.

- 모든 stored property가 비교됩니다.
- 비교 순서를 제어할 수 없습니다.
- 일부 프로퍼티만 비교하려면 `==`를 직접 구현해야 합니다.
- 클로저나 함수 타입이 포함되면 자동 합성이 실패합니다.

즉, 간단한 모델 하나에도 보일러플레이트가 쉽게 늘어납니다. `AutoEquatable`은 이 문제를 "선언은 개발자가, 구현은 매크로가" 담당하는 방식으로 풀어냅니다.

- 비교 대상은 어노테이션으로 선언
- 비교 순서는 priority로 명시
- 불필요한 프로퍼티는 제외
- 실제 비교 로직은 컴파일 타임에 생성

## Features

- `Equatable` 구현 자동 생성
- 비교 대상 프로퍼티 제외: `@AutoIgnored`
- 반드시 비교해야 하는 필드 명시: `@AutoRequired`
- KeyPath 기반 비교: `@AutoRequiredChild`
- 비교 순서 제어: `@AutoPriority`
- 선언 순서 안정성 보장
- 클로저 / 함수 타입 자동 제외
- Swift Macro 기반 컴파일 타임 코드 생성

## How to Use

```swift
struct Profile {
    let email: String
    let age: Int
}

@AutoEquatable
struct User {
    // 가장 먼저 비교할 핵심 식별자
    @AutoPriority(0)
    let id: Int

    // 어노테이션이 없으면 기본적으로 비교 대상입니다.
    let name: String

    // 하위 KeyPath 기준 비교
    @AutoRequiredChild(\Profile.email)
    let profile: Profile

    // 클로저 / 함수 타입은 자동으로 비교 대상에서 제외됩니다.
    let onTap: () -> Void
}
```

컴파일 타임에는 아래와 같은 코드가 생성됩니다.

```swift
extension User: Equatable {}
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        if lhs.profile.email != rhs.profile.email { return false }
        return true
    }
}
```

## Annotations

### `@AutoEquatable`

타입에 `Equatable` 채택과 `==` 구현을 자동으로 생성합니다.

```swift
@AutoEquatable
struct Model {
    let id: Int
}
```

생성 코드:

```swift
extension Model: Equatable {}
extension Model {
    static func == (lhs: Model, rhs: Model) -> Bool {
        if lhs.id != rhs.id { return false }
        return true
    }
}
```

### `@AutoIgnored`

해당 프로퍼티를 비교 대상에서 제외합니다.

```swift
@AutoEquatable
struct User {
    let id: Int
    @AutoIgnored let cacheTimestamp: Date
}
```

생성 코드:

```swift
extension User: Equatable {}
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        return true
    }
}
```

### `@AutoRequired`

해당 프로퍼티가 비교 대상임을 명시적으로 드러냅니다.

> `@AutoRequired`는 우선순위를 변경하지 않습니다. 기본적으로 모든 stored property는 비교 대상이며, 이 어노테이션은 의도를 명확히 드러내는 역할을 합니다.

```swift
@AutoEquatable
struct User {
    let id: Int
    @AutoRequired let name: String
}
```

생성 코드:

```swift
extension User: Equatable {}
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        return true
    }
}
```

### `@AutoRequiredChild`

하위 프로퍼티를 KeyPath 기준으로 비교합니다.

```swift
struct Profile {
    let email: String
    let age: Int
}

@AutoEquatable
struct User {
    let id: Int

    @AutoRequiredChild(\Profile.email)
    let profile: Profile
}
```

생성 코드:

```swift
extension User: Equatable {}
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.profile.email != rhs.profile.email { return false }
        return true
    }
}
```

### `@AutoPriority(Int)`

비교 순서를 명시적으로 제어합니다. 값이 낮을수록 먼저 비교됩니다.

```swift
@AutoEquatable
struct User {
    @AutoPriority(0) let id: Int
    let name: String
}
```

생성 코드:

```swift
extension User: Equatable {}
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        return true
    }
}
```

## Ordering Rule

비교 순서는 다음 규칙을 따릅니다.

1. `@AutoPriority` 값이 낮은 순서
2. priority가 같다면 선언 순서 유지

즉, 아래와 같은 선언은 항상 동일한 비교 순서를 보장합니다.

```swift
struct User {
    let id: Int
    let name: String
    let age: Int
}
```

## Closure Handling

기본 `Equatable` 자동 합성은 클로저(Function) 타입이 포함되면 실패합니다.

```swift
struct User: Equatable {
    let id: Int
    let onTap: () -> Void
}
// Equatable 자동 합성 불가
```

반면 `AutoEquatable`은 함수/클로저 타입을 자동으로 비교 대상에서 제외합니다.

```swift
@AutoEquatable
struct User {
    let id: Int
    let onTap: () -> Void
}
```

생성 코드:

```swift
extension User: Equatable {}
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        return true
    }
}
```

추가 어노테이션 없이도 `Equatable` 합성이 가능한 형태로 정리해 주기 때문에, SwiftUI View나 상태 모델에서 특히 유용합니다.
