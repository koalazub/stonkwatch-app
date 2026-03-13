import Foundation
import SwiftData

@MainActor
@Observable
final class WatchlistViewModel {
    private(set) var stocks: [Stock] = []
    private(set) var tickerDigests: [String: Digest] = [:]
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var syncState: TursoConnectionState = .disconnected

    private let api = APIClient.shared
    private let turso = TursoSyncEngine.shared
    private let session = UserSession.current

    func loadWatchlist(from modelContext: ModelContext) async {
        isLoading = true
        error = nil

        do {
            let tursoEntries = await loadWatchlistFromTurso()

            if !tursoEntries.isEmpty {
                stocks = tursoEntries.map { entry in
                    Stock.mock(
                        ticker: entry.symbol,
                        name: entry.symbol,
                        lastPrice: 0,
                        priceChangePercent: 0
                    )
                }
                session.updateWatchlistTickers(tursoEntries.map(\.symbol))
            } else {
                let descriptor = FetchDescriptor<Stock>(
                    predicate: #Predicate { $0.isFollowed },
                    sortBy: [SortDescriptor(\.ticker)]
                )
                stocks = try modelContext.fetch(descriptor)

                if stocks.isEmpty {
                    let mocks = [
                        Stock.mock(ticker: "AAPL", name: "Apple Inc.", lastPrice: 198.50, priceChangePercent: 1.23),
                        Stock.mock(ticker: "TSLA", name: "Tesla Inc.", lastPrice: 241.30, priceChangePercent: -2.10),
                        Stock.mock(ticker: "NVDA", name: "NVIDIA Corp.", lastPrice: 875.40, priceChangePercent: 3.45),
                        Stock.mock(ticker: "META", name: "Meta Platforms", lastPrice: 502.10, priceChangePercent: 0.15),
                    ]
                    for mock in mocks {
                        modelContext.insert(mock)
                    }
                    stocks = mocks
                }

                session.updateWatchlistTickers(stocks.map(\.ticker))
            }

            for stock in stocks {
                let digests = try await api.fetchFeedDigests(for: stock.ticker)
                if let digest = digests.first {
                    tickerDigests[stock.ticker] = digest
                }
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func addStock(_ ticker: String, to modelContext: ModelContext) async {
        do {
            try await turso.addToWatchlist(userId: session.userId, symbol: ticker)
            await loadWatchlist(from: modelContext)
        } catch {
            self.error = error
        }
    }

    func removeStock(_ ticker: String, from modelContext: ModelContext) async {
        do {
            try await turso.removeFromWatchlist(userId: session.userId, symbol: ticker)
            await loadWatchlist(from: modelContext)
        } catch {
            self.error = error
        }
    }

    func refreshFromTurso(modelContext: ModelContext) async {
        do {
            _ = try await turso.forceSync()
            await loadWatchlist(from: modelContext)
        } catch {
            self.error = error
        }
    }

    private func loadWatchlistFromTurso() async -> [TursoWatchlistEntry] {
        guard await turso.isConnected else { return [] }
        return (try? await turso.fetchWatchlist(userId: session.userId)) ?? []
    }
}
