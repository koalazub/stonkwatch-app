import SwiftUI

struct SentimentView: View {
    @State private var viewModel = SentimentViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.scores.isEmpty {
                    LoadingStateView(message: "Reading the room...")
                } else if let error = viewModel.error, viewModel.scores.isEmpty {
                    ErrorStateView(error: error) {
                        Task { await viewModel.loadSentiment() }
                    }
                } else {
                    sentimentContent
                }
            }
            .navigationTitle("Sentiment")
            .refreshable {
                await viewModel.loadSentiment()
            }
            .task {
                if viewModel.scores.isEmpty {
                    await viewModel.loadSentiment()
                }
            }
        }
    }

    private var sentimentContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // AI narrative at the top -- the whole point
                if let narrative = viewModel.narrative {
                    narrativeCard(narrative)
                }

                // Individual ticker scores below
                ForEach(viewModel.scores) { score in
                    SentimentRow(score: score)
                }
            }
            .padding(.horizontal)
        }
    }

    private func narrativeCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label("AI Analysis", systemImage: "brain.head.profile")
                .font(.digestCaption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.digestBody)
        }
        .cardStyle()
    }
}

// MARK: - Sentiment Row

private struct SentimentRow: View {
    let score: SentimentScore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(score.ticker)
                    .font(.tickerSymbol)
                Text("\(score.sampleSize) signals analysed")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            sentimentGauge

            SentimentBadge(level: score.level)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var sentimentGauge: some View {
        Gauge(value: (score.score + 1) / 2) {
            EmptyView()
        }
        .gaugeStyle(.accessoryLinear)
        .tint(AppTheme.sentimentColor(for: score.level))
        .frame(width: 80)
    }
}

#Preview {
    SentimentView()
}
