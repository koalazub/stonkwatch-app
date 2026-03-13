import Foundation

@MainActor
@Observable
final class ForumsViewModel {
    private(set) var threads: [ForumThread] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var selectedSymbol: String?

    private let api = APIClient.shared
    private let turso = TursoSyncEngine.shared

    func loadThreads(symbol: String? = nil) async {
        isLoading = true
        error = nil
        selectedSymbol = symbol

        do {
            let tursoThreads = await loadFromTurso(symbol: symbol)

            if !tursoThreads.isEmpty {
                threads = tursoThreads.map { entry in
                    ForumThread(
                        id: entry.id,
                        title: entry.title,
                        authorName: entry.authorUsername,
                        ticker: entry.symbol,
                        replyCount: entry.replyCount,
                        createdAt: entry.createdAt,
                        aiSummary: entry.aiSummary,
                        isPinned: entry.isPinned
                    )
                }
            } else {
                threads = try await api.fetchForumThreads(for: symbol)
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        do {
            _ = try await turso.forceSync()
            await loadThreads(symbol: selectedSymbol)
        } catch {
            await loadThreads(symbol: selectedSymbol)
        }
    }

    private func loadFromTurso(symbol: String?) async -> [TursoDiscussionThread] {
        guard await turso.isConnected else { return [] }
        return (try? await turso.fetchDiscussionThreads(symbol: symbol)) ?? []
    }
}
