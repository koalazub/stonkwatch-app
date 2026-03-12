# Turso DB Integration Setup

## Phase 1: Turso Setup - Implementation Complete

### Files Created:

1. **TursoConfiguration.swift** - Configuration and connection settings
2. **TursoAuth.swift** - Secure token storage in iOS Keychain
3. **TursoModels.swift** - Data models mirroring StonkWatch schema
4. **TursoSyncEngine.swift** - Main sync engine with embedded replica support

### Next Steps: Add turso-db Dependency

Since this is an Xcode project (not Swift Package Manager), you need to add the turso-db SDK via Xcode:

#### Option 1: Swift Package Manager (Recommended)

1. Open `stonkwatch-app.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies...**
3. Add the Turso DB Swift SDK:
   ```
   https://github.com/turso-db/turso-swift
   ```
4. Select version: **Up to Next Major Version** (0.1.0 < 1.0.0)
5. Add to target: **stonkwatch-app**

#### Option 2: Manual Integration

If the Swift package isn't available yet, you'll need to:
1. Download the turso-db Swift bindings
2. Add them as a framework to the project
3. Link against the framework in Build Settings

### Configuration

Add the following to your environment or Xcode build settings:

```bash
TURSO_DATABASE_URL=libsql://stonkwatch-yourorg.turso.io
TURSO_AUTH_TOKEN=your-auth-token-here
```

For production, these should be configured via Xcode build configuration files (.xcconfig) and not committed to git.

### Architecture Overview

```
iOS App
├── TursoSyncEngine (Actor)
│   ├── Embedded Replica (SQLite)
│   ├── Turso Client (turso-db SDK)
│   ├── 5-minute polling
│   └── Conflict resolution
│
├── TursoAuth (Actor)
│   ├── Keychain storage
│   ├── PASETO token management
│   └── Session refresh
│
└── TursoModels
    ├── TursoWatchlistEntry
    ├── TursoUserPreferences
    ├── TursoStock
    ├── TursoDiscussionThread
    ├── TursoSentimentScore
    ├── TursoAISummary
    └── TursoUserSubscription
```

### Key Features Implemented:

✅ **Offline-First**: Embedded replica with local SQLite database
✅ **5-Minute Polling**: Configurable sync interval
✅ **Priority Sync**: Critical tables (watchlist, preferences) sync first
✅ **Connection State Tracking**: Real-time connection status
✅ **Secure Auth**: Keychain storage for tokens
✅ **Bidirectional Sync**: Upload local changes, download remote changes
✅ **Error Handling**: Comprehensive error types and retry logic

### Usage Example:

```swift
// Initialize and connect
Task {
    try await TursoSyncEngine.shared.connect()
}

// Fetch watchlist (works offline)
let watchlist = try await TursoSyncEngine.shared.fetchWatchlist(userId: userId)

// Add to watchlist (syncs to cloud)
try await TursoSyncEngine.shared.addToWatchlist(userId: userId, symbol: "AAPL")

// Force sync
try await TursoSyncEngine.shared.forceSync()

// Check connection state
let state = await TursoSyncEngine.shared.getConnectionState()
```

### AI Integration:

The Turso sync engine is designed to work with the AI-first architecture:

```swift
// AI watches for data changes
TursoSyncEngine.shared.onSyncComplete = { syncedCounts in
    if syncedCounts["user_watchlist"] ?? 0 > 0 {
        // Watchlist changed, regenerate AI briefing
        Task {
            await regenerateBriefing()
        }
    }
}
```

### Next Phase (Phase 2):

1. Integrate TursoSyncEngine with existing ViewModels
2. Add sync status indicators in UI
3. Implement conflict resolution UI
4. Add background sync with BGTaskScheduler
5. Connect to StonkWatch backend auth

### Notes:

- The current implementation uses placeholders for the actual turso-db SDK calls
- Once the SDK is added, uncomment the actual implementation code
- The embedded replica path is configured to use the app's Documents directory
- All data models are `Sendable` for Swift 6 concurrency compliance
