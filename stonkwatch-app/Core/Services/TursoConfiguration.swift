import Foundation

/// Configuration for Turso DB connection
/// Supports both cloud connection and local embedded replicas
struct TursoConfiguration {
    /// Turso database URL (e.g., "libsql://stonkwatch-yourorg.turso.io")
    let databaseURL: String
    
    /// Authentication token for Turso (PASETO or API token)
    let authToken: String
    
    /// Local path for embedded replica
    let localReplicaPath: URL
    
    /// Sync interval in seconds (default: 300 = 5 minutes)
    let syncInterval: TimeInterval
    
    /// Enable offline mode with local replica
    let enableOfflineMode: Bool
    
    /// Priority tables that sync first
    let priorityTables: [String]
    
    static let `default` = TursoConfiguration(
        databaseURL: ProcessInfo.processInfo.environment["TURSO_DATABASE_URL"] ?? "",
        authToken: ProcessInfo.processInfo.environment["TURSO_AUTH_TOKEN"] ?? "",
        localReplicaPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("turso_replica.db"),
        syncInterval: 300, // 5 minutes
        enableOfflineMode: true,
        priorityTables: ["user_watchlist", "user_preferences", "stocks"]
    )
    
    /// Validate configuration
    var isValid: Bool {
        !databaseURL.isEmpty && !authToken.isEmpty
    }
}

/// Turso sync modes
enum TursoSyncMode {
    /// Bidirectional sync - upload local changes, download remote changes
    case bidirectional
    
    /// Download only - only fetch remote changes (read-only mode)
    case downloadOnly
    
    /// Upload only - only push local changes (rarely used)
    case uploadOnly
}

/// Turso connection state
enum TursoConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(lastSync: Date?)
    case syncing
    case error(Error)
    
    static func == (lhs: TursoConnectionState, rhs: TursoConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected):
            return true
        case (.connecting, .connecting):
            return true
        case (.connected(let lhsDate), .connected(let rhsDate)):
            return lhsDate == rhsDate
        case (.syncing, .syncing):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

/// Turso sync error types
enum TursoSyncError: Error {
    case invalidConfiguration
    case authenticationFailed
    case networkError(Error)
    case databaseError(String)
    case syncConflict(String)
    case replicaNotInitialized
    case tableNotFound(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidConfiguration:
            return "Invalid Turso configuration"
        case .authenticationFailed:
            return "Authentication failed - check your auth token"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .syncConflict(let table):
            return "Sync conflict detected in table: \(table)"
        case .replicaNotInitialized:
            return "Local replica not initialized"
        case .tableNotFound(let table):
            return "Table not found: \(table)"
        }
    }
}
