import Foundation

struct Digest: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let summary: String
    let ticker: String?
    let sourceCount: Int
    let sentiment: SentimentLevel
    let generatedAt: Date
    let keyPoints: [String]
    let summarizationMethod: String  // Track which tier was used

    init(
        id: String = UUID().uuidString,
        title: String,
        summary: String,
        ticker: String? = nil,
        sourceCount: Int = 0,
        sentiment: SentimentLevel = .neutral,
        generatedAt: Date? = nil,
        keyPoints: [String] = [],
        summarizationMethod: String = "extractive"
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.ticker = ticker
        self.sourceCount = sourceCount
        self.sentiment = sentiment
        self.generatedAt = generatedAt ?? Date()
        self.keyPoints = keyPoints
        self.summarizationMethod = summarizationMethod
    }
}

extension Digest {
    static func mock() -> Digest {
        Digest(
            title: "AAPL Morning Briefing",
            summary: "Apple beat Q3 earnings estimates with $94.8B revenue. Services hit an all-time high. Community sentiment is strongly bullish with 78% positive posts in the last 24 hours.",
            ticker: "AAPL",
            sourceCount: 12,
            sentiment: .bullish,
            generatedAt: Date(),
            keyPoints: [
                "Revenue: $94.8B (beat est. $92.1B)",
                "Services revenue: $24.2B (all-time high)",
                "Community sentiment: 78% bullish",
                "Analyst consensus: Overweight"
            ]
        )
    }
}
