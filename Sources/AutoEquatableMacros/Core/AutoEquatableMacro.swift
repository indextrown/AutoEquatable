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
        
        // 2) 비교 대상 stored property 이름 추출(클로저/함수 타입 제외)
         let propertyNames = extractComparableStoredPropertyNames(from: declaration)
        
        // 3) 비교식 생성
        // - 비교 대상이 없으면 항상 true(빈 타입도 Equtable로 만들기 위함
        let compareBody: String
        if propertyNames.isEmpty {
            compareBody = "return true"
        } else {
            let lines = propertyNames
                .map { "lhs.\($0) == rhs.\($0)" }
                .joined(separator: " &&\n")
            compareBody =
            """
            return (
            \(IndentUtils.indentLines(lines, level: 1))
            )
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
    
    /// stored property 중 Equatable 비교에 포함할 이름만 추출
    /// 규칙
    /// - stored property만 포함
    /// - static 제외
    /// - computed(get/set)제외
    /// - 함수/클로저 타입 제외
    private static func extractComparableStoredPropertyNames(from decl: some DeclGroupSyntax) -> [String] {
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
    
//    private static let indent = "    " // 4 spaces
//    private static func indentLines(_ text: String, level: Int) -> String {
//        let prefix = String(repeating: indent, count: level)
//        return text
//            .split(separator: "\n", omittingEmptySubsequences: false)
//            .map { prefix + $0 }
//            .joined(separator: "\n")
//    }
}
