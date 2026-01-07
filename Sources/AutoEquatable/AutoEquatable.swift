// The Swift Programming Language
// https://docs.swift.org/swift-book

// MARK: - Type Macro
// 타입에 Equatable 채택 + == 자동 생성
@attached(extension, conformances: Equatable)
@attached(member, names: named(==))
public macro AutoEquatable() =
#externalMacro(module: "AutoEquatableMacros", type: "AutoEquatableMacro")

// MARK: - Property markers
@attached(peer)
public macro AutoPriority(_ value: Int) =
#externalMacro(module: "AutoEquatableMacros", type: "AutoPriorityMacro")

@attached(peer)
public macro AutoIgnored() =
#externalMacro(module: "AutoEquatableMacros", type: "AutoIgnoredMacro")

@attached(peer)
public macro AutoRequired() =
#externalMacro(module: "AutoEquatableMacros", type: "AutoRequiredMacro")
