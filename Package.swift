// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AutoEquatable",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        
        // 런타임 라이브러리
        .library(
            name: "AutoEquatable",
            targets: ["AutoEquatable"]
        ),
        
        // 예제용 실행 파일
        .executable(
            name: "AutoEquatableClient",
            targets: ["AutoEquatableClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        
        // =========================
        // 1️⃣ Macro 타겟 (컴파일 타임 전용)
        // =========================
        .macro(
            name: "AutoEquatableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // MARK: - Public Library
        // =========================
        // 2️⃣ 런타임 라이브러리
        // =========================
        .target(name: "AutoEquatable", dependencies: []),

        // MARK: - Client
        // =========================
       // 3️⃣ Client (예제)
       // =========================
        .executableTarget(name: "AutoEquatableClient", dependencies: ["AutoEquatable"]),

        // MARK: - Tests
        // =========================
        // 4️⃣ Tests
        // =========================
        .testTarget(name: "AutoEquatableTests",
                    dependencies: [
                        "AutoEquatableMacros",
                        .product(name: "SwiftSyntax", package: "swift-syntax"),
                    ])
    ]
)
