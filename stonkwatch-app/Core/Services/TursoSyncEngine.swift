import Foundation

/// Main Turso sync engine - manages embedded replica and cloud synchronization
/// Implements 5-minute polling with offline-first architecture
actor TursoSyncEngine {
    static let shared = TursoSyncEngine()
    
    // MARK: - Properties
    
    private var configuration: TursoConfiguration
    private var connectionState: TursoConnectionState = .disconnected
    private var syncTimer: Timer?
    private var lastSyncTimes: [String: Date] = [:]
    private var client: TursoClient?
    
    // MARK: - Callbacks
    
    var onStateChange: ((TursoConnectionState) -> Void)?
    var onSyncComplete: (([String: Int]) -> Void)?  // Table -> record count
    var onError: ((TursoSyncError) -> Void)?
    
    // MARK: - Initialization
    
    private init(configuration: TursoConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Connection Management
    
    /// Initialize the embedded replica and connect to Turso
    func connect() async throws {
        guard configuration.isValid else {
            throw TursoSyncError.invalidConfiguration
        }
        
        await updateState(.connecting)
        
        do {
            // Initialize turso-db client with embedded replica
            let client = try await TursoClient(
                url: configuration.databaseURL,
                authToken: configuration.authToken
            )
            
            if configuration.enableOfflineMode {
                try await client.enableSync(
                    localPath: configuration.localReplicaPath.path,
                    syncInterval: configuration.syncInterval
                )
            }
            
            self.client = client
            await updateState(.connected(lastSync: nil))
            
            // Start periodic sync
            startPeriodicSync()
            
        } catch {
            await updateState(.error(error))
            throw TursoSyncError.networkError(error)
        }
    }
    
    /// Disconnect from Turso and stop sync
    func disconnect() {
        syncTimer?.invalidate()
        syncTimer = nil
        client = nil
        Task {
            await updateState(.disconnected)
        }
    }
    
    /// Check if currently connected
    var isConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }
    
    /// Get current connection state
    func getConnectionState() -> TursoConnectionState {
        connectionState
    }
    
    // MARK: - Sync Operations
    
    /// Perform immediate sync with Turso cloud
    func sync(mode: TursoSyncMode = .bidirectional) async throws -> [String: Int] {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        await updateState(.syncing)
        
        var syncedCounts: [String: Int] = [:]
        
        do {
            // Sync priority tables first
            for table in configuration.priorityTables {
                let count = try await syncTable(table, mode: mode)
                syncedCounts[table] = count
                lastSyncTimes[table] = Date()
            }
            
            await updateState(.connected(lastSync: Date()))
            
            // Notify completion
            if let callback = onSyncComplete {
                await MainActor.run {
                    callback(syncedCounts)
                }
            }
            
            return syncedCounts
            
        } catch {
            await updateState(.error(error))
            throw error
        }
    }
    
    /// Sync a specific table
    private func syncTable(_ table: String, mode: TursoSyncMode) async throws -> Int {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        switch mode {
        case .bidirectional:
            return try await client.syncTable(table)
        case .downloadOnly:
            return try await client.downloadChanges(table: table)
        case .uploadOnly:
            return try await client.uploadChanges(table: table)
        }
    }
    
    /// Force immediate sync (can be called from UI)
    func forceSync() async throws -> [String: Int] {
        try await sync(mode: .bidirectional)
    }
    
    // MARK: - Data Access Methods
    
    /// Fetch user's watchlist from local replica
    func fetchWatchlist(userId: String) async throws -> [TursoWatchlistEntry] {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let results = try await client.query(
            """
            SELECT id, user_id, symbol, added_at, notifications_enabled, 
                   alert_price_high, alert_price_low
            FROM user_watchlist 
            WHERE user_id = ?
            ORDER BY added_at DESC
            """,
            parameters: [userId]
        )
        
        return try results.map { row in
            try row.decode(TursoWatchlistEntry.self)
        }
    }
    
    /// Add stock to watchlist
    func addToWatchlist(userId: String, symbol: String) async throws {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let id = UUID().uuidString
        let now = Date()
        
        try await client.execute(
            """
            INSERT INTO user_watchlist (id, user_id, symbol, added_at, notifications_enabled)
            VALUES (?, ?, ?, ?, ?)
            """,
            parameters: [id, userId, symbol, now, true]
        )
        
        // Trigger sync for immediate update
        Task {
            try? await sync(mode: .uploadOnly)
        }
    }
    
    /// Remove stock from watchlist
    func removeFromWatchlist(userId: String, symbol: String) async throws {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        try await client.execute(
            """
            DELETE FROM user_watchlist 
            WHERE user_id = ? AND symbol = ?
            """,
            parameters: [userId, symbol]
        )
        
        Task {
            try? await sync(mode: .uploadOnly)
        }
    }
    
    /// Fetch user preferences
    func fetchUserPreferences(userId: String) async throws -> TursoUserPreferences? {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let results = try await client.query(
            """
            SELECT user_id, theme, notifications_enabled, digest_frequency,
                   ai_summary_length, default_timeframe, updated_at
            FROM user_preferences 
            WHERE user_id = ?
            """,
            parameters: [userId]
        )
        
        return try results.first?.decode(TursoUserPreferences.self)
    }
    
    /// Update user preferences
    func updateUserPreferences(_ preferences: TursoUserPreferences) async throws {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
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
                preferences.userId,
                preferences.theme,
                preferences.notificationsEnabled,
                preferences.digestFrequency,
                preferences.aiSummaryLength,
                preferences.defaultTimeframe,
                preferences.updatedAt
            ]
        )
        
        Task {
            try? await sync(mode: .uploadOnly)
        }
    }
    
    /// Fetch stocks
    func fetchStocks() async throws -> [TursoStock] {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let results = try await client.query(
            """
            SELECT id, symbol, company_name, sector, market_cap, exchange, 
                   is_active, last_updated
            FROM stocks 
            WHERE is_active = true
            ORDER BY symbol
            """
        )
        
        return try results.map { row in
            try row.decode(TursoStock.self)
        }
    }
    
    /// Fetch discussion threads
    func fetchDiscussionThreads(symbol: String? = nil, limit: Int = 50) async throws -> [TursoDiscussionThread] {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let query: String
        let parameters: [Any]
        
        if let symbol = symbol {
            query = """
                SELECT id, title, symbol, thread_type, author_id, author_username,
                       created_at, reply_count, is_pinned, is_locked, 
                       latest_message_preview, ai_summary
                FROM discussion_threads 
                WHERE symbol = ? AND is_locked = false
                ORDER BY is_pinned DESC, created_at DESC
                LIMIT ?
                """
            parameters = [symbol, limit]
        } else {
            query = """
                SELECT id, title, symbol, thread_type, author_id, author_username,
                       created_at, reply_count, is_pinned, is_locked,
                       latest_message_preview, ai_summary
                FROM discussion_threads 
                WHERE is_locked = false
                ORDER BY is_pinned DESC, created_at DESC
                LIMIT ?
                """
            parameters = [limit]
        }
        
        let results = try await client.query(query, parameters: parameters)
        
        return try results.map { row in
            try row.decode(TursoDiscussionThread.self)
        }
    }
    
    /// Fetch sentiment scores
    func fetchSentimentScores(ticker: String, timeframe: String = "24h") async throws -> [TursoSentimentScore] {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let results = try await client.query(
            """
            SELECT ticker, score, confidence, post_count, timeframe, calculated_at
            FROM ticker_sentiments 
            WHERE ticker = ? AND timeframe = ?
            ORDER BY calculated_at DESC
            LIMIT 100
            """,
            parameters: [ticker, timeframe]
        )
        
        return try results.map { row in
            try row.decode(TursoSentimentScore.self)
        }
    }
    
    /// Fetch AI summaries
    func fetchAISummaries(ticker: String) async throws -> [TursoAISummary] {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let results = try await client.query(
            """
            SELECT id, ticker, summary, key_points, sentiment, confidence,
                   source_count, generated_at, expires_at
            FROM ai_summaries 
            WHERE ticker = ?
            AND (expires_at IS NULL OR expires_at > datetime('now'))
            ORDER BY generated_at DESC
            LIMIT 10
            """,
            parameters: [ticker]
        )
        
        return try results.map { row in
            try row.decode(TursoAISummary.self)
        }
    }
    
    /// Fetch user subscription info
    func fetchUserSubscription(userId: String) async throws -> TursoUserSubscription? {
        guard let client = client else {
            throw TursoSyncError.replicaNotInitialized
        }
        
        let results = try await client.query(
            """
            SELECT user_id, tier, status, current_period_start, current_period_end,
                   ai_summaries_remaining, ai_summaries_quota
            FROM user_subscriptions 
            WHERE user_id = ?
            """,
            parameters: [userId]
        )
        
        return try results.first?.decode(TursoUserSubscription.self)
    }
    
    // MARK: - Private Methods
    
    private func startPeriodicSync() {
        syncTimer?.invalidate()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: configuration.syncInterval, repeats: true) { [weak self] _ in
            Task {
                do {
                    try await self?.sync()
                } catch {
                    print("Periodic sync failed: \(error)")
                }
            }
        }
    }
    
    private func updateState(_ newState: TursoConnectionState) async {
        connectionState = newState
        
        if let callback = onStateChange {
            await MainActor.run {
                callback(newState)
            }
        }
    }
    
    /// Get time since last sync for a table
    func timeSinceLastSync(table: String) -> TimeInterval? {
        guard let lastSync = lastSyncTimes[table] else {
            return nil
        }
        return Date().timeIntervalSince(lastSync)
    }
}

// MARK: - Turso Client Protocol (Placeholder for actual SDK)

/// Protocol defining the Turso client interface
/// This will be replaced by the actual turso-db SDK when available
protocol TursoClient {
    init(url: String, authToken: String) async throws
    func enableSync(localPath: String, syncInterval: TimeInterval) async throws
    func syncTable(_ table: String) async throws -> Int
    func downloadChanges(table: String) async throws -> Int
    func uploadChanges(table: String) async throws -> Int
    func query(_ sql: String, parameters: [Any]) async throws -> [TursoRow]
    func execute(_ sql: String, parameters: [Any]) async throws
}

/// Protocol for query results
protocol TursoRow {
    func decode<T: Decodable>(_ type: T.Type) throws -> T
}

// MARK: - Convenience Extensions

extension TursoSyncEngine {
    /// Check if data is stale (needs sync)
    func isDataStale(table: String, maxAge: TimeInterval = 300) -> Bool {
        guard let timeSince = timeSinceLastSync(table: table) else {
            return true // Never synced, definitely stale
        }
        return timeSince > maxAge
    }
    
    /// Format time since last sync for UI display
    func formattedTimeSinceLastSync(table: String) -> String {
        guard let timeSince = timeSinceLastSync(table: table) else {
            return "Never synced"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: Date().addingTimeInterval(-timeSince), relativeTo: Date())
    }
}
