import SwiftUI
import SwiftData

@main
struct stonkwatch_appApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Stock.self,
            Post.self,
            ForumThread.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var appSettings = AppSettings.shared
    
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Briefing", systemImage: "brain.head.profile") {
                    LivingBriefingView()
                }
                Tab("Discussions", systemImage: "bubble.left.and.text.bubble.right") {
                    ForumsView()
                }
                Tab("Sentiment", systemImage: "chart.line.uptrend.xyaxis") {
                    SentimentView()
                }
                Tab("Watchlist", systemImage: "star") {
                    WatchlistView()
                }
                Tab("Settings", systemImage: "gearshape") {
                    SettingsView()
                }
            }
            .preferredColorScheme(appSettings.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
