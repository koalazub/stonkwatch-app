import Foundation

@MainActor
@Observable
final class SentimentViewModel {
    private(set) var scores: [SentimentScore] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var narrative: String?

    private let api = APIClient.shared
    private let turso = TursoSyncEngine.shared
    private let session = UserSession.current

    func loadSentiment() async {
        isLoading = true
        error = nil

        do {
            let tickers = session.watchlistTickers
            let tursoScores = await loadFromTurso(tickers: tickers)

            if !tursoScores.isEmpty {
                scores = tursoScores.map { entry in
                    let level: SentimentLevel = switch entry.score {
                    case 0.6...:   .veryBullish
                    case 0.2..<0.6: .bullish
                    case (-0.2)..<0.2: .neutral
                    case (-0.6)..<(-0.2): .bearish
                    default: .veryBearish
                    }
                    return SentimentScore(
                        ticker: entry.ticker,
                        level: level,
                        score: entry.score,
                        sampleSize: entry.postCount,
                        measuredAt: entry.calculatedAt
                    )
                }
            } else {
                scores = try await api.fetchSentimentOverview()
            }

            narrative = generateNarrative(from: scores)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        do {
            _ = try await turso.forceSync()
            await loadSentiment()
        } catch {
            await loadSentiment()
        }
    }

    private func loadFromTurso(tickers: [String]) async -> [TursoSentimentScore] {
        guard await turso.isConnected else { return [] }
        var all: [TursoSentimentScore] = []
        for ticker in tickers {
            let entries = (try? await turso.fetchSentimentScores(ticker: ticker)) ?? []
            if let latest = entries.first {
                all.append(latest)
            }
        }
        return all
    }

    private func generateNarrative(from scores: [SentimentScore]) -> String {
        guard !scores.isEmpty else { return "" }
        let bullish = scores.filter { $0.score > 0.3 }
        let bearish = scores.filter { $0.score < -0.3 }

        var parts: [String] = []
        if !bullish.isEmpty {
            parts.append("Community is bullish on \(bullish.map(\.ticker).joined(separator: ", ")).")
        }
        if !bearish.isEmpty {
            parts.append("Bearish sentiment around \(bearish.map(\.ticker).joined(separator: ", ")).")
        }
        if parts.isEmpty {
            parts.append("Sentiment is mostly neutral across your watchlist today.")
        }
        return parts.joined(separator: " ")
    }
}
