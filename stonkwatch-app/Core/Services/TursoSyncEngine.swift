import Foundation

actor TursoSyncEngine {
    static let shared = TursoSyncEngine()

    private var configuration: TursoConfiguration
    private var connectionState: TursoConnectionState = .disconnected
    private var syncTask: Task<Void, Never>?
    private var lastSyncTimes: [String: Date] = [:]
    private var client: TursoClientStub?

    var onStateChange: ((TursoConnectionState) -> Void)?
    var onSyncComplete: (([String: Int]) -> Void)?
    var onError: ((TursoSyncError) -> Void)?

    private init(configuration: TursoConfiguration = .default) {
        self.configuration = configuration
    }

    func connect() async throws {
        guard configuration.isValid else {
            throw TursoSyncError.invalidConfiguration
        }

        updateState(.connecting)

        let stub = TursoClientStub(
            url: configuration.databaseURL,
            authToken: configuration.authToken
        )

        if configuration.enableOfflineMode {
            stub.configureEmbeddedReplica(
                localPath: configuration.localReplicaPath.path,
                syncInterval: configuration.syncInterval
            )
        }

        client = stub
        updateState(.connected(lastSync: nil))
        startPeriodicSync()
    }

    func disconnect() {
        syncTask?.cancel()
        syncTask = nil
        client = nil
        updateState(.disconnected)
    }

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    func getConnectionState() -> TursoConnectionState {
        connectionState
    }

    func sync(mode: TursoSyncMode = .bidirectional) async throws -> [String: Int] {
        guard let client else {
            throw TursoSyncError.replicaNotInitialized
        }

        updateState(.syncing)

        do {
            var syncedCounts: [String: Int] = [:]

            for table in configuration.priorityTables {
                let count = try await performTableSync(table, client: client, mode: mode)
                syncedCounts[table] = count
                lastSyncTimes[table] = Date()
            }

            updateState(.connected(lastSync: Date()))

            if let callback = onSyncComplete {
                let counts = syncedCounts
                await MainActor.run { callback(counts) }
            }

            return syncedCounts

        } catch {
            updateState(.error(error))
            throw error
        }
    }

    func forceSync() async throws -> [String: Int] {
        try await sync(mode: .bidirectional)
    }

    func fetchWatchlist(userId: String) async throws -> [TursoWatchlistEntry] {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        return try await client.query(
            """
            SELECT id, user_id, symbol, added_at, notifications_enabled,
                   alert_price_high, alert_price_low
            FROM user_watchlist
            WHERE user_id = ?
            ORDER BY added_at DESC
            """,
            parameters: [.text(userId)],
            as: TursoWatchlistEntry.self
        )
    }

    func addToWatchlist(userId: String, symbol: String) async throws {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        try await client.execute(
            """
            INSERT INTO user_watchlist (id, user_id, symbol, added_at, notifications_enabled)
            VALUES (?, ?, ?, ?, ?)
            """,
            parameters: [
                .text(UUID().uuidString),
                .text(userId),
                .text(symbol),
                .text(ISO8601DateFormatter().string(from: Date())),
                .integer(1)
            ]
        )

        Task { try? await sync(mode: .uploadOnly) }
    }

    func removeFromWatchlist(userId: String, symbol: String) async throws {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        try await client.execute(
            """
            DELETE FROM user_watchlist
            WHERE user_id = ? AND symbol = ?
            """,
            parameters: [.text(userId), .text(symbol)]
        )

        Task { try? await sync(mode: .uploadOnly) }
    }

    func fetchUserPreferences(userId: String) async throws -> TursoUserPreferences? {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        let results = try await client.query(
            """
            SELECT user_id, theme, notifications_enabled, digest_frequency,
                   ai_summary_length, default_timeframe, updated_at
            FROM user_preferences
            WHERE user_id = ?
            """,
            parameters: [.text(userId)],
            as: TursoUserPreferences.self
        )

        return results.first
    }

    func updateUserPreferences(_ preferences: TursoUserPreferences) async throws {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        try await client.execute(
            """
            INSERT INTO user_preferences (user_id, theme, notifications_enabled,
                                         digest_frequency, ai_summary_length,
                                         default_timeframe, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
                theme = excluded.theme,
                notifications_enabled = excluded.notifications_enabled,
                digest_frequency = excluded.digest_frequency,
                ai_summary_length = excluded.ai_summary_length,
                default_timeframe = excluded.default_timeframe,
                updated_at = excluded.updated_at
            """,
            parameters: [
                .text(preferences.userId),
                .text(preferences.theme),
                .integer(preferences.notificationsEnabled ? 1 : 0),
                .text(preferences.digestFrequency),
                .text(preferences.aiSummaryLength),
                .text(preferences.defaultTimeframe),
                .text(ISO8601DateFormatter().string(from: preferences.updatedAt))
            ]
        )

        Task { try? await sync(mode: .uploadOnly) }
    }

    func fetchStocks() async throws -> [TursoStock] {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        return try await client.query(
            """
            SELECT id, symbol, company_name, sector, market_cap, exchange,
                   is_active, last_updated
            FROM stocks
            WHERE is_active = 1
            ORDER BY symbol
            """,
            parameters: [],
            as: TursoStock.self
        )
    }

    func fetchDiscussionThreads(symbol: String? = nil, limit: Int = 50) async throws -> [TursoDiscussionThread] {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        if let symbol {
            return try await client.query(
                """
                SELECT id, title, symbol, thread_type, author_id, author_username,
                       created_at, reply_count, is_pinned, is_locked,
                       latest_message_preview, ai_summary
                FROM discussion_threads
                WHERE symbol = ? AND is_locked = 0
                ORDER BY is_pinned DESC, created_at DESC
                LIMIT ?
                """,
                parameters: [.text(symbol), .integer(limit)],
                as: TursoDiscussionThread.self
            )
        } else {
            return try await client.query(
                """
                SELECT id, title, symbol, thread_type, author_id, author_username,
                       created_at, reply_count, is_pinned, is_locked,
                       latest_message_preview, ai_summary
                FROM discussion_threads
                WHERE is_locked = 0
                ORDER BY is_pinned DESC, created_at DESC
                LIMIT ?
                """,
                parameters: [.integer(limit)],
                as: TursoDiscussionThread.self
            )
        }
    }

    func fetchSentimentScores(ticker: String, timeframe: String = "24h") async throws -> [TursoSentimentScore] {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        return try await client.query(
            """
            SELECT ticker, score, confidence, post_count, timeframe, calculated_at
            FROM ticker_sentiments
            WHERE ticker = ? AND timeframe = ?
            ORDER BY calculated_at DESC
            LIMIT 100
            """,
            parameters: [.text(ticker), .text(timeframe)],
            as: TursoSentimentScore.self
        )
    }

    func fetchAISummaries(ticker: String) async throws -> [TursoAISummary] {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        return try await client.query(
            """
            SELECT id, ticker, summary, key_points, sentiment, confidence,
                   source_count, generated_at, expires_at
            FROM ai_summaries
            WHERE ticker = ?
            AND (expires_at IS NULL OR expires_at > datetime('now'))
            ORDER BY generated_at DESC
            LIMIT 10
            """,
            parameters: [.text(ticker)],
            as: TursoAISummary.self
        )
    }

    func fetchUserSubscription(userId: String) async throws -> TursoUserSubscription? {
        guard let client else { throw TursoSyncError.replicaNotInitialized }

        let results = try await client.query(
            """
            SELECT user_id, tier, status, current_period_start, current_period_end,
                   ai_summaries_remaining, ai_summaries_quota
            FROM user_subscriptions
            WHERE user_id = ?
            """,
            parameters: [.text(userId)],
            as: TursoUserSubscription.self
        )

        return results.first
    }

    func timeSinceLastSync(table: String) -> TimeInterval? {
        guard let lastSync = lastSyncTimes[table] else { return nil }
        return Date().timeIntervalSince(lastSync)
    }

    func isDataStale(table: String, maxAge: TimeInterval = 300) -> Bool {
        guard let timeSince = timeSinceLastSync(table: table) else { return true }
        return timeSince > maxAge
    }

    func formattedTimeSinceLastSync(table: String) -> String {
        guard let timeSince = timeSinceLastSync(table: table) else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: Date().addingTimeInterval(-timeSince), relativeTo: Date())
    }

    private func performTableSync(_ table: String, client: TursoClientStub, mode: TursoSyncMode) async throws -> Int {
        switch mode {
        case .bidirectional: return try await client.syncTable(table)
        case .downloadOnly: return try await client.downloadChanges(table: table)
        case .uploadOnly: return try await client.uploadChanges(table: table)
        }
    }

    private func startPeriodicSync() {
        syncTask?.cancel()
        let interval = configuration.syncInterval

        syncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                try? await self?.sync()
            }
        }
    }

    private func updateState(_ newState: TursoConnectionState) {
        connectionState = newState

        if let callback = onStateChange {
            Task { @MainActor in callback(newState) }
        }
    }
}

// MARK: - SQL Parameter Value

enum TursoValue: Sendable {
    case text(String)
    case integer(Int)
    case real(Double)
    case null
}

// MARK: - Placeholder Client

final class TursoClientStub: Sendable {
    private let url: String
    private let authToken: String

    init(url: String, authToken: String) {
        self.url = url
        self.authToken = authToken
    }

    func configureEmbeddedReplica(localPath: String, syncInterval: TimeInterval) {
    }

    func syncTable(_ table: String) async throws -> Int { 0 }
    func downloadChanges(table: String) async throws -> Int { 0 }
    func uploadChanges(table: String) async throws -> Int { 0 }

    func query<T: Decodable & Sendable>(
        _ sql: String,
        parameters: [TursoValue],
        as type: T.Type
    ) async throws -> [T] { [] }

    func execute(_ sql: String, parameters: [TursoValue]) async throws {}
}
