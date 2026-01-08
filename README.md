#  AutoEquatable
> AutoEquatable은 SwiftUI의 불필요한 View 재계산을 줄이기 위해
> View의 동등성 기준을 선언적으로 정의하고  
> `Equatable` 구현을 컴파일 타임에 자동 생성하는 Swift Macro입니다.

<!-- <img
  src="https://github.com/user-attachments/assets/48cc1dab-ad53-4e4a-aeeb-974e9e581cec"
  width="400"
/> -->

<img
  src="https://github.com/user-attachments/assets/3938e583-0fc4-4620-99b0-bf761e60a1ba"
  width="400"
/>
## SwiftUI에서 불필요한 View 업데이트를 멈추세요

SwiftUI에서 하나의 셀만 변경했는데
의미 있는 변화가 없는 다른 View들까지 다시 그려지는 문제를 겪어본 적 있나요?    
- 이 문제는 SwiftUI의 diffing 과정에서 “이전 View와 새로운 View가 같은지 판단할 기준이 없을 때” 발생합니다.  
- SwiftUI는 View를 다시 그릴지 결정하기 위해 View의 타입과 구조를 기반으로 변경 여부를 추론합니다.
- 아래 코드는 SwiftUI의 내부 diffing 과정을 개념적으로 표현한 의사 코드입니다.

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
    
    // 4. 클로저는 비교 불가능 - 항상 다르다고 가정
    if containsClosures(V.self) {
        return true
    }
}
```
> ⚠️ 위 코드는 실제 SwiftUI 구현이 아니라
> View diffing의 의사 결정 흐름을 설명하기 위한 개념적 예시입니다.

## 기존에 사용되던 해결 방법들
1. `EqutableView` 사용 or View에 `Equtable` 채택하여 동등성(==)기준 직접 정의
2. `.equtable()` modifier 적용(View 비교를 SwiftUI diffing 단계에 명시적으로 참여시킴)
3. 수동 `static func ==` 수동 구현(보일러플레이트 코드 발생)      

이 과정은 효과적이지만,  
- 코드가 장황해지고
- 비교 기준이 View 정의와 분리되며
- 수정 시 실수하기 쉽고 유지보수가 어렵다는 단점이 있습니다.

> AutoEquatable는 이러한 문제를 선언적으로 해결하기 위해 만들어졌습니다.  
> 비교 기준을 타입 정의에서 명확히 선언하고,  
> SwiftUI diffing 과정에서 불필요한 body 재계산을 줄이기 위한  
> `Equatable` 구현을 컴파일 타임에 안전하게 생성합니다.  

---

## AutoEquatable란?
`AutoEquatable`는 Swift Macro를 이용해 `Equatable` 구현을 자동 생성하면서도  
- 무엇을 비교할지
- 어떤 순서로 비교할지
를 어노테이션(DSL) 형태로 명확하게 선언할 수 있도록 설계된 라이브러리입니다.

---

## AutoEquatable = Equatable 최적화를 위한 DSL
@AutoEquatable를 사용하면 SwiftUI에서 .equatable()을 안전하고, 짧고, 의도적으로 사용할 수 있습니다.
- ✅ 변경되지 않은 셀은 다시 그리지 않음
- ✅ 비교 기준을 타입 정의에서 명확히 선언
- ✅ 실수하기 쉬운 == 구현을 컴파일 타임에 생성
- ✅ SwiftUI List 성능 최적화를 위한 최소 비용 도구

---

## 왜 필요한가?
Swift의 기본 `Equatable` 자동 합성은 편리하지만, 실제 앱 프로젝트에서는 다음과 같은 한계에 자주 부딪힙니다.
- 모든 stored property가 비교됨
- 비교 순서를 제어할 수 없음
- 일부 프로퍼티만 비교하려면 `==` 보일러 플레이트를 직접 구현해야 함
- 클로저/함수 타입이 포함되면 Equatable 자동 합성이 아예 실패
=> 결국 간단한 모델 하나에도 `==` 구현이 보일러플레이트로 늘어나는 문제가 생깁니다.

## AutoEquatable 철학
AutoEquatable는 이 문제를 선언적 DSL + 컴파일 타임 코드 생성으로 해결합니다.
- 비교 대상은 어노테이션으로 선언
- 비교 순서는 priority로 명시
- 불필요한 프로퍼티는 제외
- 실제 비교 로직은 컴파일 타임에 생성
=> 의도는 선언으로, 구현은 매크로가 책입집니다.

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
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        if lhs.profile.email != rhs.profile.email { return false }
        return true
    }
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
extension Model: {
    static func == (lhs: Model, rhs: Model) -> Bool {
        if lhs.id != rhs.id { return false }
        return true
    }
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

extension User: Equatable {}
extension User: {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        return true
    }
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

extension User: Equatable {}
extension User: {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        return true
    }
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

extension User: Equatable {}
extension User: {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.profile.email != rhs.profile.email { return false }
        return true
    }
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

extension User: Equatable {}
extension User: {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        return true
    }
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

## Closure Handling 
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

extension User: Equatable {}
extension User: {
    static func == (lhs: User, rhs: User) -> Bool {
        if lhs.id != rhs.id { return false }
        return true
    }
}
```
`AutoEquatable`는 이 문제를 컴파일 타임에 해결합니다.
- 함수/클로저 타입은 자동으로 비교 대상에서 제외
- 추가 어노테이션 없이도 Equatable 합성 가능
