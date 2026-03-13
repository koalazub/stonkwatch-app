import Foundation

@Observable
final class UserSession {
    static let current = UserSession()

    private(set) var userId: String
    var watchlistTickers: [String]
    var isAuthenticated: Bool

    private static let userIdKey = "stonkwatch_user_id"
    private static let tickersKey = "stonkwatch_watchlist_tickers"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.userIdKey)
        if let stored {
            userId = stored
        } else {
            let generated = UUID().uuidString
            UserDefaults.standard.set(generated, forKey: Self.userIdKey)
            userId = generated
        }

        watchlistTickers = UserDefaults.standard.stringArray(forKey: Self.tickersKey) ?? [
            "AAPL", "TSLA", "NVDA", "META"
        ]
        isAuthenticated = false
    }

    func updateWatchlistTickers(_ tickers: [String]) {
        watchlistTickers = tickers
        UserDefaults.standard.set(tickers, forKey: Self.tickersKey)
    }

    func signIn(userId: String) {
        self.userId = userId
        self.isAuthenticated = true
        UserDefaults.standard.set(userId, forKey: Self.userIdKey)
    }

    func signOut() {
        isAuthenticated = false
    }
}
