// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AutoEquatable",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AutoEquatable",
            targets: ["AutoEquatable"]
        ),
        .executable(
            name: "AutoEquatableClient",
            targets: ["AutoEquatableClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "AutoEquatableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // MARK: - Public Library
        .target(name: "AutoEquatable", dependencies: ["AutoEquatableMacros"]),

        // MARK: - Client
        .executableTarget(name: "AutoEquatableClient", dependencies: ["AutoEquatable"]),

        // MARK: - Tests
        .testTarget(name: "AutoEquatableTests",
                    dependencies: [
                        "AutoEquatableMacros",
                        .product(name: "SwiftSyntax", package: "swift-syntax"),
                    ])
    ]
)
