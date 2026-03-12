import Foundation

@Observable
final class SentimentViewModel {
    private(set) var scores: [SentimentScore] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var narrative: String?

    private let api = APIClient.shared

    func loadSentiment() async {
        isLoading = true
        error = nil
        do {
            scores = try await api.fetchSentimentOverview()
            narrative = generateNarrative(from: scores)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    /// AI-generated narrative explaining sentiment across the watchlist.
    /// In production this comes from the backend; here we synthesise locally.
    private func generateNarrative(from scores: [SentimentScore]) -> String {
        guard !scores.isEmpty else { return "" }
        let bullish = scores.filter { $0.score > 0.3 }
        let bearish = scores.filter { $0.score < -0.3 }

        var parts: [String] = []
        if !bullish.isEmpty {
            let tickers = bullish.map(\.ticker).joined(separator: ", ")
            parts.append("Community is bullish on \(tickers).")
        }
        if !bearish.isEmpty {
            let tickers = bearish.map(\.ticker).joined(separator: ", ")
            parts.append("Bearish sentiment around \(tickers).")
        }
        if parts.isEmpty {
            parts.append("Sentiment is mostly neutral across your watchlist today.")
        }
        return parts.joined(separator: " ")
    }
}
