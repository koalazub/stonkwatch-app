import Foundation

@Observable
final class ForumsViewModel {
    private(set) var threads: [ForumThread] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let api = APIClient.shared

    func loadThreads() async {
        isLoading = true
        error = nil
        do {
            threads = try await api.fetchForumThreads()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
