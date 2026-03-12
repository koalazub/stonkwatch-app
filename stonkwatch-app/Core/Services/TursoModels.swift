import Foundation

// MARK: - Turso Data Models
// Mirrors the StonkWatch database schema for seamless sync

/// User watchlist entry - synced with turso.user_watchlist
struct TursoWatchlistEntry: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let symbol: String
    let addedAt: Date
    let notificationsEnabled: Bool
    let alertPriceHigh: Double?
    let alertPriceLow: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbol
        case addedAt = "added_at"
        case notificationsEnabled = "notifications_enabled"
        case alertPriceHigh = "alert_price_high"
        case alertPriceLow = "alert_price_low"
    }
}

/// User preferences - synced with turso.user_preferences
struct TursoUserPreferences: Codable, Sendable {
    let userId: String
    let theme: String
    let notificationsEnabled: Bool
    let digestFrequency: String
    let aiSummaryLength: String
    let defaultTimeframe: String
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case theme
        case notificationsEnabled = "notifications_enabled"
        case digestFrequency = "digest_frequency"
        case aiSummaryLength = "ai_summary_length"
        case defaultTimeframe = "default_timeframe"
        case updatedAt = "updated_at"
    }
}

/// Stock metadata - synced with turso.stocks
struct TursoStock: Codable, Identifiable, Sendable {
    let id: String
    let symbol: String
    let companyName: String
    let sector: String?
    let marketCap: Int64?
    let exchange: String
    let isActive: Bool
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case companyName = "company_name"
        case sector
        case marketCap = "market_cap"
        case exchange
        case isActive = "is_active"
        case lastUpdated = "last_updated"
    }
}

/// Current price data - synced with turso.current_prices
struct TursoCurrentPrice: Codable, Sendable {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case price
        case change
        case changePercent = "change_percent"
        case volume
        case updatedAt = "updated_at"
    }
}

/// Discussion thread - synced with turso.discussion_threads
struct TursoDiscussionThread: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let symbol: String?
    let threadType: String
    let authorId: String
    let authorUsername: String
    let createdAt: Date
    let replyCount: Int
    let isPinned: Bool
    let isLocked: Bool
    let latestMessagePreview: String?
    let aiSummary: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case symbol
        case threadType = "thread_type"
        case authorId = "author_id"
        case authorUsername = "author_username"
        case createdAt = "created_at"
        case replyCount = "reply_count"
        case isPinned = "is_pinned"
        case isLocked = "is_locked"
        case latestMessagePreview = "latest_message_preview"
        case aiSummary = "ai_summary"
    }
}

/// Sentiment score - synced with turso.ticker_sentiments
struct TursoSentimentScore: Codable, Sendable {
    let ticker: String
    let score: Double
    let confidence: Double
    let postCount: Int
    let timeframe: String
    let calculatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case ticker
        case score
        case confidence
        case postCount = "post_count"
        case timeframe
        case calculatedAt = "calculated_at"
    }
}

/// AI-generated summary - synced with turso.ai_summaries
struct TursoAISummary: Codable, Identifiable, Sendable {
    let id: String
    let ticker: String
    let summary: String
    let keyPoints: [String]
    let sentiment: String
    let confidence: Double
    let sourceCount: Int
    let generatedAt: Date
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ticker
        case summary
        case keyPoints = "key_points"
        case sentiment
        case confidence
        case sourceCount = "source_count"
        case generatedAt = "generated_at"
        case expiresAt = "expires_at"
    }
}

/// User subscription info - synced with turso.user_subscriptions
struct TursoUserSubscription: Codable, Sendable {
    let userId: String
    let tier: String
    let status: String
    let currentPeriodStart: Date
    let currentPeriodEnd: Date
    let aiSummariesRemaining: Int
    let aiSummariesQuota: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier
        case status
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case aiSummariesRemaining = "ai_summaries_remaining"
        case aiSummariesQuota = "ai_summaries_quota"
    }
}

// MARK: - Sync Models

/// Represents a sync batch operation
struct TursoSyncBatch: Sendable {
    let table: String
    let operation: SyncOperation
    let records: [Codable & Sendable]
    let timestamp: Date
}

enum SyncOperation: String, Sendable {
    case insert
    case update
    case delete
}

/// Sync checkpoint for tracking last sync position
struct TursoSyncCheckpoint: Codable, Sendable {
    let table: String
    let lastSyncAt: Date
    let lastRowId: Int64?
    
    enum CodingKeys: String, CodingKey {
        case table
        case lastSyncAt = "last_sync_at"
        case lastRowId = "last_row_id"
    }
}

/// Conflict resolution strategy
enum ConflictResolution: Sendable {
    case serverWins      // Remote changes override local
    case clientWins      // Local changes override remote
    case timestampWins   // Most recent timestamp wins
    case merge           // Attempt to merge changes
}
