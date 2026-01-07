import AutoEquatable
import Foundation

// MARK: - example1
@AutoEquatable
struct User {
    let id: Int
    let name: String
    let onTap: () -> Void
}

let a = User(id: 1, name: "Kim", onTap: {})
let b = User(id: 1, name: "Kim", onTap: { print("x") })
print(a == b) // true (onTap 제외라서)


// MARK: - example2
@AutoEquatable
struct FeedItem {

    // === 기본 stored properties (비교 대상) ===
    let id: Int
    let title: String
    let subtitle: String?
    let isLiked: Bool
    let likeCount: Int
    let createdAt: Date

    // === 컬렉션 타입 ===
    let tags: [String]
    let metadata: [String: String]

    // === 커스텀 타입 (Equatable이라고 가정) ===
    let author: Author

    // === computed property (자동 제외) ===
    var summary: String {
        "\(title) - \(subtitle ?? "")"
    }

    // === static property (자동 제외) ===
    static let defaultLikeCount = 0

    // === 클로저 (자동 제외) ===
    let onTap: () -> Void
    let onLike: (Int) -> Void
    let onAppear: () -> Void
}

struct Author: Equatable {
    let id: Int
    let name: String
}

/*
static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
    return (
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.isLiked == rhs.isLiked &&
        lhs.likeCount == rhs.likeCount &&
        lhs.createdAt == rhs.createdAt &&
        lhs.tags == rhs.tags &&
        lhs.metadata == rhs.metadata &&
        lhs.author == rhs.author
    )
}
*/

let c = FeedItem(
    id: 1,
    title: "Hello",
    subtitle: "World",
    isLiked: true,
    likeCount: 10,
    createdAt: Date(),
    tags: ["swift", "macro"],
    metadata: ["source": "home"],
    author: Author(id: 1, name: "Kim"),
    onTap: {},
    onLike: { _ in },
    onAppear: {}
)

let d = FeedItem(
    id: 1,
    title: "Hello",
    subtitle: "World",
    isLiked: true,
    likeCount: 10,
    createdAt: c.createdAt,
    tags: ["swift", "macro"],
    metadata: ["source": "home"],
    author: Author(id: 1, name: "Kim"),
    onTap: { print("tap") },
    onLike: { print($0) },
    onAppear: {}
)

print(c == d) // ✅ true (클로저 전부 무시)

