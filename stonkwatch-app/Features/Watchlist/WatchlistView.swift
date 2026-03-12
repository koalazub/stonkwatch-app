import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WatchlistViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stocks.isEmpty {
                    LoadingStateView(message: "Loading your watchlist...")
                } else if let error = viewModel.error, viewModel.stocks.isEmpty {
                    ErrorStateView(error: error) {
                        Task { await viewModel.loadWatchlist(from: modelContext) }
                    }
                } else if viewModel.stocks.isEmpty {
                    ContentUnavailableView(
                        "No stocks followed",
                        systemImage: "star",
                        description: Text("Follow stocks to get AI briefings here.")
                    )
                } else {
                    stockList
                }
            }
            .navigationTitle("Watchlist")
            .refreshable {
                await viewModel.loadWatchlist(from: modelContext)
            }
            .task {
                if viewModel.stocks.isEmpty {
                    await viewModel.loadWatchlist(from: modelContext)
                }
            }
        }
    }

    private var stockList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.stocks) { stock in
                    StockBriefingCard(
                        stock: stock,
                        digest: viewModel.tickerDigests[stock.ticker]
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Stock Briefing Card (AI digest per ticker, not just price)

private struct StockBriefingCard: View {
    let stock: Stock
    let digest: Digest?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(stock.ticker)
                        .font(.tickerSymbol)
                    Text(stock.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                priceView
            }

            // AI digest is the main content, not an afterthought
            if let digest {
                Divider()
                Text(digest.summary)
                    .font(.digestBody)
                    .foregroundStyle(.secondary)

                HStack {
                    SentimentBadge(level: digest.sentiment)
                    Spacer()
                    Label("\(digest.sourceCount) sources", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .cardStyle()
    }

    private var priceView: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
            if let price = stock.lastPrice {
                Text(price, format: .currency(code: "USD"))
                    .font(.priceLabel)
            }
            if let change = stock.priceChangePercent {
                Text(change, format: .percent.precision(.fractionLength(2)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.priceChangeColor(change))
            }
        }
    }
}

#Preview {
    WatchlistView()
        .modelContainer(for: Stock.self, inMemory: true)
}
