import Foundation
import SwiftUI

@MainActor
@Observable
final class LivingBriefingViewModel {
    private(set) var digests: [Digest] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var lastUpdateTime: Date?
    private(set) var newDevelopmentsCount = 0
    private(set) var currentTier: SummarizationTier = .auto
    private(set) var syncStatus: TursoConnectionState = .disconnected

    private let summarizationService = SummarizationService.shared
    private let api = APIClient.shared
    private let turso = TursoSyncEngine.shared
    private var updateTask: Task<Void, Never>?
    private var lastViewedTime: Date?

    func startLivingUpdates() {
        Task { currentTier = await summarizationService.getCurrentTier() }
        Task { await loadBriefing() }

        updateTask?.cancel()
        updateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { break }
                await checkForUpdates()
            }
        }
    }

    func stopLivingUpdates() {
        updateTask?.cancel()
        updateTask = nil
        lastViewedTime = Date()
    }

    func loadBriefing() async {
        isLoading = true
        error = nil

        do {
            let tursoDigests = await loadFromTurso()

            if !tursoDigests.isEmpty {
                digests = tursoDigests
            } else {
                let posts = try await api.fetchPosts()
                let grouped = Dictionary(grouping: posts) { $0.ticker ?? "MARKET" }
                var built: [Digest] = []
                for (ticker, tickerPosts) in grouped {
                    let digest = await summarizationService.summarizePosts(
                        tickerPosts,
                        ticker: ticker,
                        config: .briefing
                    )
                    built.append(digest)
                }
                digests = built
            }

            lastUpdateTime = Date()
            lastViewedTime = Date()
            newDevelopmentsCount = 0
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func forceSync() async {
        do {
            _ = try await turso.forceSync()
            await loadBriefing()
        } catch {
            self.error = error
        }
    }

    func freshness(for digest: Digest) -> ContentFreshness {
        let age = Date().timeIntervalSince(digest.generatedAt)
        switch age {
        case 0..<900:   return .fresh
        case 900..<3600: return .recent
        case 3600..<14400: return .aging
        default:         return .stale
        }
    }

    func executeAction(_ action: PredictedAction, for digest: Digest) {
        switch action {
        case .addToWatchlist: addToWatchlist(digest.ticker)
        case .setAlert:       setPriceAlert(for: digest.ticker)
        case .viewContrary:   showContraryView(for: digest)
        case .saveToThesis:   saveToThesis(digest)
        case .share:          shareInsight(digest)
        }
    }

    private func loadFromTurso() async -> [Digest] {
        guard await turso.isConnected else { return [] }

        let watchlistTickers = UserSession.current.watchlistTickers
        guard !watchlistTickers.isEmpty else { return [] }

        var digests: [Digest] = []
        for ticker in watchlistTickers {
            guard let summary = try? await turso.fetchAISummaries(ticker: ticker).first else { continue }

            let sentiment: SentimentLevel = switch summary.sentiment {
            case "bullish":     .bullish
            case "bearish":     .bearish
            case "veryBullish": .veryBullish
            case "veryBearish": .veryBearish
            default:            .neutral
            }

            let digest = Digest(
                title: "\(ticker) Market Update",
                summary: summary.summary,
                ticker: ticker,
                sourceCount: summary.sourceCount,
                sentiment: sentiment,
                keyPoints: summary.keyPoints,
                summarizationMethod: "tursoAI"
            )
            digests.append(digest)
        }
        return digests
    }

    private func checkForUpdates() async {
        do {
            let fresh = try await api.fetchPosts()
            let grouped = Dictionary(grouping: fresh) { $0.ticker ?? "MARKET" }
            var built: [Digest] = []
            for (ticker, posts) in grouped {
                let digest = await summarizationService.summarizePosts(posts, ticker: ticker, config: .briefing)
                built.append(digest)
            }
            if built != digests {
                withAnimation(.spring()) {
                    digests = built
                    newDevelopmentsCount += 1
                    lastUpdateTime = Date()
                }
                triggerUpdateHaptic()
            }
        } catch {}
    }

    private func triggerUpdateHaptic() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func addToWatchlist(_ ticker: String?) {
        guard let ticker else { return }
        Task { try? await turso.addToWatchlist(userId: UserSession.current.userId, symbol: ticker) }
    }

    private func setPriceAlert(for ticker: String?) {}
    private func showContraryView(for digest: Digest) {}
    private func saveToThesis(_ digest: Digest) {}
    private func shareInsight(_ digest: Digest) {}
}

extension Digest {
    var confidence: Double {
        min(0.75 + Double(sourceCount) * 0.02, 0.95)
    }

    var tierBadge: String {
        switch summarizationMethod {
        case "appleIntelligence": "Apple Intelligence"
        case "coreML":            "Core ML"
        case "tursoAI":           "Live AI"
        default:                  "On-Device"
        }
    }
}
