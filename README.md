#  AutoEquatable
> Swift Macro로 Equtable 구현을 선언적으로 제어할 수 있습니다

`AutoEquatable`는 Swift Macro를 이용해  
`Equatable` 구현을 자동 생성하면서도  
- 무엇을 비교할지
- 어떤 순서로 비교할지
를 어노테이션(DSL) 형태로 명확하게 선언할 수 있도록 설계된 라이브러리입니다.

Swift의 기본 `Equatable` 자동 합성은 간단하지만 실제 앱 프로젝트에서는 다음과 같은 한계가 있습니다.
- 모든 stored property가 비교됨
- 비교 순서를 제어할 수 없음
- 일부 프로퍼티만 비교하려면 `==` 보일러 플레이트 구현 필요
- KeyPath 기반 비교가 어려움
- 클로저/함수 타입이 있으면 Equatable 자동 합성이 아예 실패
`AutoEquatable`는 이 문제를 선언적 DSL + 컴파일 타임 코드 생성으로 해결합니다.

---

## ✨ Features

- ✅ `Equatable` 구현 자동 생성
- ✅ 비교 대상 프로퍼티 제외 (`@AutoIgnored`)
- ✅ 반드시 비교해야 하는 필드 명시 (`@AutoRequired`)
- ✅ KeyPath 기반 비교 (`@AutoRequiredChild`)
- ✅ 비교 순서 제어 (`@AutoPriority`)
- ✅ 선언 순서 안정성 보장 (stable ordering)
- ✅ 클로저 / 함수 타입 자동 제외
- ✅ Swift Macro 기반 (컴파일 타임 코드 생성)

---

## ✅ How to Use
```swift
struct Profile {
    let email: String
    let age: Int
}

@AutoEquatable
struct User {

    // 가장 먼저 비교하고 싶은 핵심 식별자
    @AutoPriority(0)
    let id: Int
    
    // 어노테이션을 쓰지 않으면 기본 비교 대상입니다 (@AutoRequired)
    let name: String
    
    // 하위 KeyPath 기준 비교
    @AutoRequiredChild(\Profile.email)
    let profile: Profile
    
    // 클로저 / 함수 타입은 자동 비교 대상에서 제외됩니다 (@AutoIgnored)
    let onTap: () -> Void
}

⬇️ 컴파일 타임에 자동 생성

extension User: Equatable {}
static func == (lhs: User, rhs: User) -> Bool {
    if lhs.id != rhs.id { return false }
    if lhs.name != rhs.name { return false }
    if lhs.profile.email != rhs.profile.email { return false }
    return true
}
```

## 🧩 Annotations
### @AutoEquatable
타입에 `Equatable` 채택 + `==`구현을 자동 생성합니다.
```swift
@AutoEquatable
struct Model {
    let id: Int
}

⬇️ 생성 코드

extension Model: Equatable {}
static func == (lhs: Model, rhs: Model) -> Bool {
    if lhs.id != rhs.id { return false }
    return true
}
```

### @AutoIgnored
해당 프로퍼티를 비교 대상에서 제외합니다.
```swift
@AutoEquatable
struct User {
    let id: Int
    @AutoIgnored let cacheTimestamp: Date
}

⬇️ 생성 코드

static func == (lhs: User, rhs: User) -> Bool {
    if lhs.id != rhs.id { return false }
    return true
}
```

### @AutoRequired
해당 프로퍼티가 비교 대상임을 명시적으로 드러냅니다.
> ⚠️ 우선순위를 변경하지 않습니다
> 기본적으로 모든 stored property는 비교 대상이며
> `@AutoRequired`는 의도를 드러내는 어노테이션 역할을 합니다.
```swift
@AutoEquatable
struct User {
    let id: Int
    @AutoRequired let name: String
}

⬇️ 생성 코드

static func == (lhs: User, rhs: User) -> Bool {
    if lhs.id != rhs.id { return false }
    if lhs.name != rhs.name { return false }
    return true
}
```

### @AutoRequiredChild
하위 프로퍼티(KeyPath) 기준으로 비교합니다.
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

⬇️ 생성 코드

static func == (lhs: User, rhs: User) -> Bool {
    if lhs.id != rhs.id { return false }
    if lhs.profile.email != rhs.profile.email { return false }
    return true
}
```

### @AutoPriority(Int)
비교 순서를 명시적으로 제어합니다. (값이 낮을수록 먼저 비교)
```swift
@AutoEquatable
struct User {
    @AutoPriority(0) let id: Int
    let name: String
}

⬇️ 생성 코드

static func == (lhs: User, rhs: User) -> Bool {
    if lhs.id != rhs.id { return false }
    if lhs.name != rhs.name { return false }
    return true
}
```

## Ordering Rule (중요)
비교 순서는 다음 규칙을 따릅니다.
1. `@AutoPriority` 값이 낮은 순
2. priority가 같으면 선언 순서 유지
즉, 아래 선언은 항상 동일한 비교 순서를 보장합니다.
```swift
struct User {
    let id: Int
    let name: String
    let age: Int
}
```

## Closure Handling (차별점)
```swift
struct User: Equatable {
    let id: Int
    let onTap: () -> Void
}
// ❌ Equatable 합성 불가
```
- Swift의 기본 `Equatable` 자동 합성은 클로저(Function) 타입이 하나라도 포함되면 컴파일이 실패합니다.


```swift
@AutoEquatable
struct User {
    let id: Int
    let onTap: () -> Void
}

⬇️ 생성 코드

static func == (lhs: User, rhs: User) -> Bool {
    if lhs.id != rhs.id { return false }
    return true
}

```
`AutoEquatable`는 이 문제를 컴파일 타임에 해결합니다.
- 함수/클로저 타입은 자동으로 비교 대상에서 제외
- 추가 어노테이션 없이도 Equatable 합성 가능

## 💡 Design Philosophy
- 컴파일 타임 코드 생성
- 선언적 DSL -> 비교 로직이 타입 정의에 드러남
