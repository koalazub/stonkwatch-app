import Foundation
import SwiftData

@Model
final class ForumThread {
    @Attribute(.unique) var id: String
    var title: String
    var authorName: String
    var ticker: String?
    var replyCount: Int
    var lastActivityAt: Date
    var createdAt: Date
    var aiSummary: String?
    var isPinned: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        authorName: String,
        ticker: String? = nil,
        replyCount: Int = 0,
        lastActivityAt: Date? = nil,
        createdAt: Date? = nil,
        aiSummary: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.authorName = authorName
        self.ticker = ticker
        self.replyCount = replyCount
        self.lastActivityAt = lastActivityAt ?? Date()
        self.createdAt = createdAt ?? Date()
        self.aiSummary = aiSummary
        self.isPinned = isPinned
    }
}

extension ForumThread {
    nonisolated static func mock() -> ForumThread {
        let now = Date()
        return ForumThread(
            title: "AAPL post-earnings discussion",
            authorName: "macro_mike",
            ticker: "AAPL",
            replyCount: 47,
            lastActivityAt: now.addingTimeInterval(-600),
            createdAt: now.addingTimeInterval(-86400),
            aiSummary: "Community is largely bullish after earnings beat. Main debate is around Services growth sustainability vs. hardware margin pressure.",
            isPinned: true
        )
    }
}
