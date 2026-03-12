import Foundation

struct SentimentScore: Identifiable, Sendable {
    let id: String
    let ticker: String
    let level: SentimentLevel
    let score: Double // -1.0 (very bearish) to 1.0 (very bullish)
    let sampleSize: Int
    let period: SentimentPeriod
    let measuredAt: Date

    init(
        id: String = UUID().uuidString,
        ticker: String,
        level: SentimentLevel,
        score: Double,
        sampleSize: Int,
        period: SentimentPeriod = .day,
        measuredAt: Date? = nil
    ) {
        self.id = id
        self.ticker = ticker
        self.level = level
        self.score = score
        self.sampleSize = sampleSize
        self.period = period
        self.measuredAt = measuredAt ?? Date()
    }
}

enum SentimentLevel: String, Codable, Sendable, CaseIterable {
    case veryBearish
    case bearish
    case neutral
    case bullish
    case veryBullish

    var label: String {
        switch self {
        case .veryBearish: "Very Bearish"
        case .bearish: "Bearish"
        case .neutral: "Neutral"
        case .bullish: "Bullish"
        case .veryBullish: "Very Bullish"
        }
    }
}

enum SentimentPeriod: String, Codable, Sendable {
    case hour
    case day
    case week
    case month
}

extension SentimentScore {
    static func mock(
        ticker: String = "AAPL",
        score: Double = 0.72,
        level: SentimentLevel = .bullish
    ) -> SentimentScore {
        SentimentScore(
            ticker: ticker,
            level: level,
            score: score,
            sampleSize: 1284,
            period: .day,
            measuredAt: Date()
        )
    }
}
