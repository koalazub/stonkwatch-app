import Foundation

@MainActor
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - Generic request

    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Briefing (AI-generated digest for followed stocks)

    func fetchBriefing() async throws -> [Digest] {
        // TODO: Wire to real endpoint
        // Simulates the AI backend returning pre-computed digests
        try await Task.sleep(nanoseconds: 800_000_000)
        return [
            Digest.mock(),
            Digest(
                title: "TSLA Sentiment Shift",
                summary: "Community sentiment flipped bearish overnight after delivery numbers missed expectations. Forums are debating whether this is a buying opportunity or the start of a trend reversal. Analyst consensus remains Hold.",
                ticker: "TSLA",
                sourceCount: 8,
                sentiment: .bearish,
                keyPoints: [
                    "Q3 deliveries: 435K (missed est. 461K)",
                    "Community sentiment: 62% bearish (was 54% bullish yesterday)",
                    "Top forum debate: buying opportunity vs. trend reversal",
                    "Analyst consensus: Hold (unchanged)"
                ]
            ),
            Digest(
                title: "Market Open Summary",
                summary: "Futures point to a flat open. Tech earnings season kicks off this week. The community is most active around NVDA and META ahead of their reports.",
                sourceCount: 23,
                sentiment: .neutral,
                keyPoints: [
                    "S&P 500 futures: +0.1%",
                    "Most discussed: NVDA, META, AAPL",
                    "Earnings this week: NVDA (Tue), META (Wed)",
                    "Community mood: cautiously optimistic"
                ]
            ),
        ]
    }

    // MARK: - Feed (AI-curated social digest)

    func fetchFeedDigests(for ticker: String? = nil) async throws -> [Digest] {
        // TODO: Wire to real endpoint
        try await Task.sleep(nanoseconds: 600_000_000)
        return [.mock()]
    }

    // MARK: - Forums (AI-summarised threads)

    func fetchForumThreads(for ticker: String? = nil) async throws -> [ForumThread] {
        // TODO: Wire to real endpoint
        try await Task.sleep(nanoseconds: 500_000_000)
        return [.mock()]
    }

    // MARK: - Sentiment

    func fetchSentiment(for ticker: String) async throws -> SentimentScore {
        // TODO: Wire to real endpoint
        try await Task.sleep(nanoseconds: 400_000_000)
        return .mock(ticker: ticker)
    }

    func fetchSentimentOverview() async throws -> [SentimentScore] {
        // TODO: Wire to real endpoint
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            .mock(ticker: "AAPL", score: 0.72, level: .bullish),
            .mock(ticker: "TSLA", score: -0.34, level: .bearish),
            .mock(ticker: "NVDA", score: 0.85, level: .veryBullish),
            .mock(ticker: "META", score: 0.12, level: .neutral),
        ]
    }

    // MARK: - Posts

    func fetchPosts() async throws -> [Post] {
        // TODO: Wire to real endpoint
        try await Task.sleep(nanoseconds: 600_000_000)
        return [
            Post.mock(content: "AAPL earnings beat expectations. Revenue up 8% YoY driven by Services growth.", ticker: "AAPL"),
            Post.mock(content: "TSLA deliveries missed estimates. Community sentiment turning bearish.", ticker: "TSLA"),
            Post.mock(content: "NVDA Blackwell chips receiving strong demand. Analysts upgrading targets.", ticker: "NVDA"),
            Post.mock(content: "META investing heavily in AI infrastructure. Q3 guidance looks strong.", ticker: "META"),
            Post.mock(content: "AAPL iPhone 16 sales exceeding expectations in key markets.", ticker: "AAPL"),
        ]
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid server response"
        case .httpError(let code):
            "Server error (\(code))"
        case .decodingFailed:
            "Failed to process server data"
        }
    }
}
