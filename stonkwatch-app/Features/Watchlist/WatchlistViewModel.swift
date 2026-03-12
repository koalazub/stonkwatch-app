import Foundation
import SwiftData

@Observable
final class WatchlistViewModel {
    private(set) var stocks: [Stock] = []
    private(set) var tickerDigests: [String: Digest] = [:]
    private(set) var isLoading = false
    private(set) var error: Error?

    private let api = APIClient.shared

    func loadWatchlist(from modelContext: ModelContext) async {
        isLoading = true
        error = nil
        do {
            // Fetch followed stocks from SwiftData
            let descriptor = FetchDescriptor<Stock>(
                predicate: #Predicate { $0.isFollowed },
                sortBy: [SortDescriptor(\.ticker)]
            )
            stocks = try modelContext.fetch(descriptor)

            // If no stocks yet, seed with mocks for development
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

            // Fetch an AI digest for each stock
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
}
