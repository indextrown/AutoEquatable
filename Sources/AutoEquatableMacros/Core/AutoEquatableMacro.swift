import SwiftCompilerPlugin  // 이 타겟이 컴파일러 플러그인임을 선언
import SwiftSyntax          // Swift 코드(AST)를 구조적으로 다루기 위한 타입들
import SwiftSyntaxBuilder   // """ extension Foo {} """ 같은 문자열 → Syntax 빌더
import SwiftSyntaxMacros    // ExtensionMacro, MemberMacro, PeerMacro 등 매크로 프로토콜 정의

/*
 ExpressionMacro: 표현식을 다른 표현식으로 치환
 MemberMacro: 타입 안에 멤버 추가
 ExtensionMacro: 타입에 extension 추가
 PeerMacro: 기존 선언과 같은 레벨의 선언 추가
 */


// MARK: - 실제 매크로 구현 타입
public struct AutoEquatableMacro {}

// MARK: - @AutoEquatable
// - @attached(extension, conformances: Equatable)

/**
 @AutoEquatable
 struct User { ... }
 -> 컴파일 타입에 아래 extension 생성 역할
 extension User: Equatable {}
 */
extension AutoEquatableMacro: ExtensionMacro {
    
    /// @AutoEquatable가 붙은 타입에 Equatable 채택을 추가하는 extension을 생성한다.
    ///
    /// 이 매크로는 기존 타입 선언을 수정할 수 없기 때문에,
    /// `extension <Type>: Equatable {}` 형태의 새로운 Extension을
    /// 컴파일 타임에 추가하는 방식으로 동작한다.
    ///
    /// - Parameters:
    ///   - node: `@AutoEquatable` 어트리뷰트 자체를 나타내는 AST 노드.
    ///           (현재 구현에서는 사용하지 않지만, 이후 옵션 파싱에 활용될 수 있다.)
    ///
    ///   - declaration: 매크로가 적용된 선언 노드.
    ///                  `struct`, `class`, `enum` 등 `DeclGroupSyntax`를 채택한 타입이다.
    ///
    ///   - type: extension을 생성할 대상 타입의 타입 표현식.
    ///           예: `User`, `PopupRow` 등.
    ///
    ///   - protocols: 매크로 선언부의 `@attached(extension, conformances: ...)`에서
    ///                 요청된 프로토콜 목록.
    ///                 이 매크로에서는 `Equatable`이 전달된다.
    ///
    ///   - context: 매크로 확장 과정에서 사용되는 컴파일러 컨텍스트.
    ///              진단(Diagnostic) 출력이나 고유 이름 생성 등에 사용할 수 있다.
    ///
    /// - Returns:
    ///   생성된 `ExtensionDeclSyntax` 배열.
    ///   여기서는 `extension <Type>: Equatable {}` 하나만 반환한다.
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        /// SwiftSyntaxBuilder의 문자열 빌더는 DeclSyntax / ExprSyntax 같은 래퍼 타입에서만 동작하므로 DeclSyntax로 만들고 as()로 캐스팅
        let decl: DeclSyntax =
        """
        extension \(type): Equatable {}
        """
        
        guard let ext = decl.as(ExtensionDeclSyntax.self) else {
            // 캐스팅에 실패할 경우 확장을 생성하지 않는다.
            return []
        }
        
        return [ext]
    }
}

// MARK: - 타입 안에 멤버 추가
extension AutoEquatableMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1) 타입 이름 추출(struct만 지원)
        let typeName: String
        if let s = declaration.as(StructDeclSyntax.self) {
            typeName = s.name.text
        } else {
            // class나 enum은 추후에 고려
            return []
        }
        
        // 2) 프로퍼티 메타데이터 수집
         let propertyMetaDatas = extractProperties(from: declaration)
        
        // 3) 비교식 생성
        // - 비교 대상이 없으면 항상 true(빈 타입도 Equtable로 만들기 위함
        let compareBody: String
        if propertyMetaDatas.isEmpty {
            compareBody = "return true"
        } else {
            let lines = propertyMetaDatas.map { prop -> String in
                switch prop.kind {
                case .required:
                    // return "lhs.\(prop.name) == rhs.\(prop.name)"
                    return "if lhs.\(prop.name) != rhs.\(prop.name) { return false }"
                case .requiredChild(let keyPath):
                    // return "lhs.\(keyPath) == rhs.\(keyPath)"
                    return "if lhs.\(prop.name).\(keyPath) != rhs.\(prop.name).\(keyPath) { return false }"
                }
            }.joined(separator: "\n")
            //.joined(separator: " &&\n")
            
            compareBody =
            """
            \(IndentUtils.indentLines(lines, level: 1))
            \(IndentUtils.indentLines("return true", level: 1))
            """
        }
        
        // 4) static func == 생성
        let function =
        """
        static func == (lhs: \(typeName), rhs: \(typeName)) -> Bool {
        \(IndentUtils.indentLines(compareBody, level: 0))
        }
        """

        // 🔥 struct 내부 멤버이므로 전체를 한 번 더 들여쓰기
        let funcDecl: DeclSyntax =
        """
        \(raw: IndentUtils.indentLines(function, level: 0))
        """

        
        return [funcDecl]
    }
    
    
    /// 추출 규칙:
    /// - 기본 stored property는 전부 비교 대상 (priority=100, order=선언순서)
    /// - AutoIgnored: 비교 대상에서 제거
    /// - AutoRequired: "명시적으로 비교 대상" 의미만(결과적으로 기본과 동일한 kind) + order 유지
    /// - AutoRequiredChild: 비교 방식만 변경 + order 유지
    /// - AutoPriority: 정렬(priority)만 담당
    private static func extractProperties(
        from decl: some DeclGroupSyntax
    ) -> [EquatablePropertyInfo] {

        let allVarDecls = decl.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }

        // 1) 기본 stored property 수집 (선언 순서 기록)
        var properties: [EquatablePropertyInfo] =
            extractDefaultComparableStoredProperties(from: decl)
                .enumerated()
                .map { index, name in
                    EquatablePropertyInfo(
                        name: name,
                        kind: .required,
                        priority: 100,
                        order: index
                    )
                }

        // 2) 마커 override
        for varDecl in allVarDecls {

            // static 제외
            if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
                continue
            }

            for binding in varDecl.bindings {

                // computed 제외
                if binding.accessorBlock != nil { continue }

                guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                let name = ident.identifier.text

                // 기존 order 유지용
                let order = properties.firstIndex(where: { $0.name == name }) ?? properties.count

                // 2-1) AutoIgnored → 제거
                if AttributeUtils.hasAttribute(in: varDecl, named: "AutoIgnored") {
                    properties.removeAll { $0.name == name }
                    continue
                }

                // 2-2) AutoPriority (오직 여기서만 priority 변경)
                let explicitPriority: Int? = {
                    guard let attr = AttributeUtils.findAttribute(in: varDecl, named: "AutoPriority"),
                          let p = AttributeUtils.extractIntArgument(from: attr)
                    else { return nil }
                    return p
                }()

                // 2-3) AutoRequiredChild → 비교 방식 변경 (priority는 AutoPriority 있을 때만 변경)
                if let childAttr = AttributeUtils.findAttribute(in: varDecl, named: "AutoRequiredChild"),
                   let keyPath = KeyPathUtils.extractKeyPathString(from: childAttr) {

                    let newPriority = explicitPriority ?? 100

                    properties.removeAll { $0.name == name }
                    properties.append(
                        .init(
                            name: name,
                            kind: .requiredChild(keyPath: keyPath),
                            priority: newPriority,
                            order: order
                        )
                    )
                    continue
                }

                // 2-4) AutoRequired → "명시적으로 비교" 마커 (기본과 동일한 required)
                //      priority는 AutoPriority 있을 때만 변경
                if AttributeUtils.hasAttribute(in: varDecl, named: "AutoRequired") {

                    let newPriority = explicitPriority ?? 100

                    properties.removeAll { $0.name == name }
                    properties.append(
                        .init(
                            name: name,
                            kind: .required,
                            priority: newPriority,
                            order: order
                        )
                    )
                    continue
                }

                // 2-5) AutoPriority 단독 → 기존 항목 priority만 갱신
                if let p = explicitPriority,
                   let idx = properties.firstIndex(where: { $0.name == name }) {

                    let current = properties[idx]
                    properties[idx] = .init(
                        name: current.name,
                        kind: current.kind,
                        priority: p,
                        order: current.order
                    )
                }
            }
        }

        // 3) priority → order (선언 순서 보장)
        return properties.sorted {
            if $0.priority != $1.priority {
                return $0.priority < $1.priority
            }
            return $0.order < $1.order
        }
    }

    
    /// 기본 모드:
    /// - stored property만
    /// - static 제외
    /// - computed(get/set/observer) 제외
    /// - 함수/클로저 타입 제외
    private static func extractDefaultComparableStoredProperties(from decl: some DeclGroupSyntax) -> [String] {
        var result: [String] = []
        
        for member in decl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            
            // static 제외
            if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) { continue }
            
            for binding in varDecl.bindings {
                // computed 제외 (get/set/observer 등 accessor가 있으면 stored가 아닐 가능성이 큼)
                if binding.accessorBlock != nil { continue }
                
                // 이름 추출(let title: String)
                guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                let name = ident.identifier.text
                
                // 함수/클로저 타입 제외
                if let typeSyntax = binding.typeAnnotation?.type,
                   isFunctionLikeType(typeSyntax) { continue }
                result.append(name)
            }
        }
        return result
    }
    
    /// 함수/클로저 타입인지 판별
    /// (A) -> B, () -> Void
    private static func isFunctionLikeType(_ type: TypeSyntax) -> Bool {
        if type.as(FunctionTypeSyntax.self) != nil { return true }
        
        // @escaping (A) -> B 같은 attributed type도 처리
        if let attributed = type.as(AttributedTypeSyntax.self) {
            return attributed.baseType.as(FunctionTypeSyntax.self) != nil
        }
        
        return false
    }
}




enum EquatablePropertyKind {
    case required
    case requiredChild(keyPath: String)
}

struct EquatablePropertyInfo {
    let name: String
    let kind: EquatablePropertyKind
    let priority: Int
    let order: Int
}
