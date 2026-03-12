import Foundation
import SwiftData

@Model
final class Post: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var authorName: String
    var content: String
    var ticker: String?
    var createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var source: PostSource

    init(
        id: String = UUID().uuidString,
        authorName: String,
        content: String,
        ticker: String? = nil,
        createdAt: Date = .now,
        likeCount: Int = 0,
        commentCount: Int = 0,
        source: PostSource = .community
    ) {
        self.id = id
        self.authorName = authorName
        self.content = content
        self.ticker = ticker
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.source = source
    }
}

enum PostSource: String, Codable, CaseIterable {
    case community
    case news
    case analyst
}

extension Post {
    static func mock(
        content: String = "AAPL earnings beat expectations. Revenue up 8% YoY driven by Services growth.",
        ticker: String = "AAPL"
    ) -> Post {
        Post(
            authorName: "trader_jane",
            content: content,
            ticker: ticker,
            createdAt: .now.addingTimeInterval(-3600),
            likeCount: 42,
            commentCount: 7
        )
    }
}
