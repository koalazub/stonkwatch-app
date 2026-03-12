import SwiftUI

struct ForumsView: View {
    @State private var viewModel = ForumsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.threads.isEmpty {
                    LoadingStateView(message: "Summarising discussions...")
                } else if let error = viewModel.error, viewModel.threads.isEmpty {
                    ErrorStateView(error: error) {
                        Task { await viewModel.loadThreads() }
                    }
                } else {
                    threadList
                }
            }
            .navigationTitle("Discussions")
            .refreshable {
                await viewModel.loadThreads()
            }
            .task {
                if viewModel.threads.isEmpty {
                    await viewModel.loadThreads()
                }
            }
        }
    }

    private var threadList: some View {
        List(viewModel.threads) { thread in
            ThreadRow(thread: thread)
        }
        .listStyle(.plain)
    }
}

// MARK: - Thread Row (AI summary is the primary content)

private struct ThreadRow: View {
    let thread: ForumThread

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                if let ticker = thread.ticker {
                    Text(ticker)
                        .font(.tickerSymbol)
                        .foregroundStyle(Color.accentColor)
                }
                Text(thread.title)
                    .font(.sectionHeader)
                    .lineLimit(2)
            }

            // AI summary is front and centre -- not hidden behind a tap
            if let summary = thread.aiSummary {
                Text(summary)
                    .font(.digestBody)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("\(thread.replyCount) replies", systemImage: "bubble.left.and.bubble.right")
                Spacer()
                Text(thread.lastActivityAt.relativeDescription)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

#Preview {
    ForumsView()
}
