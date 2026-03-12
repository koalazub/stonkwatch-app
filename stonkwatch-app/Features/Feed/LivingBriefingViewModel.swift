import Foundation
import SwiftUI

@Observable
final class LivingBriefingViewModel {
    private(set) var digests: [Digest] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var lastUpdateTime: Date?
    private(set) var newDevelopmentsCount = 0
    private(set) var currentTier: SummarizationTier = .auto
    
    private let summarizationService = SummarizationService.shared
    private let api = APIClient.shared
    private var updateTimer: Timer?
    private var backgroundTask: Task<Void, Never>?
    private var lastViewedTime: Date?
    
    // MARK: - Living Briefing System
    
    func startLivingUpdates() {
        // Update current tier
        Task {
            currentTier = await summarizationService.getCurrentTier()
        }
        
        // Initial load
        Task {
            await loadBriefing()
        }
        
        // Start continuous monitoring (every 5 minutes)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForUpdates()
            }
        }
        
        // Monitor for significant updates
        backgroundTask = Task {
            await monitorForDevelopments()
        }
    }
    
    func stopLivingUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        backgroundTask?.cancel()
        backgroundTask = nil
        lastViewedTime = Date()
    }
    
    func loadBriefing() async {
        isLoading = true
        error = nil
        do {
            // Fetch posts from API
            let posts = try await api.fetchPosts()
            
            // Group posts by ticker and summarize
            var newDigests: [Digest] = []
            let groupedPosts = Dictionary(grouping: posts) { $0.ticker ?? "MARKET" }
            
            for (ticker, tickerPosts) in groupedPosts {
                let digest = await summarizationService.summarizePosts(
                    tickerPosts,
                    ticker: ticker,
                    config: .briefing
                )
                newDigests.append(digest)
            }
            
            digests = newDigests
            lastUpdateTime = Date()
            lastViewedTime = Date()
            newDevelopmentsCount = 0
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    private func checkForUpdates() async {
        do {
            let posts = try await api.fetchPosts()
            
            // Check for new posts
            _ = Set(digests.flatMap { digest in
                // This is simplified - in production track post IDs
                [digest.id]
            })
            
            // If new posts exist, regenerate digests
            let groupedPosts = Dictionary(grouping: posts) { $0.ticker ?? "MARKET" }
            var newDigests: [Digest] = []
            
            for (ticker, tickerPosts) in groupedPosts {
                let digest = await summarizationService.summarizePosts(
                    tickerPosts,
                    ticker: ticker,
                    config: .briefing
                )
                newDigests.append(digest)
            }
            
            if newDigests != digests {
                withAnimation(.spring()) {
                    digests = newDigests
                    newDevelopmentsCount += 1
                    lastUpdateTime = Date()
                }
                
                triggerUpdateHaptic()
            }
        } catch {
            print("Background update failed: \(error)")
        }
    }
    
    private func monitorForDevelopments() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 60_000_000_000)
            await checkForUpdates()
        }
    }
    
    private func triggerUpdateHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
    
    // MARK: - Confidence Decay
    
    func freshness(for digest: Digest) -> ContentFreshness {
        let age = Date().timeIntervalSince(digest.generatedAt)
        
        switch age {
        case 0..<900:
            return .fresh
        case 900..<3600:
            return .recent
        case 3600..<14400:
            return .aging
        default:
            return .stale
        }
    }
    
    // MARK: - Predictive Actions
    
    func executeAction(_ action: PredictedAction, for digest: Digest) {
        switch action {
        case .addToWatchlist:
            addToWatchlist(digest.ticker)
        case .setAlert:
            setPriceAlert(for: digest.ticker)
        case .viewContrary:
            showContraryView(for: digest)
        case .saveToThesis:
            saveToThesis(digest)
        case .share:
            shareInsight(digest)
        }
    }
    
    private func addToWatchlist(_ ticker: String?) {
        guard let ticker else { return }
        print("Adding \(ticker) to watchlist")
    }
    
    private func setPriceAlert(for ticker: String?) {
        guard let ticker else { return }
        print("Setting alert for \(ticker)")
    }
    
    private func showContraryView(for digest: Digest) {
        print("Showing contrary view for \(digest.ticker ?? "unknown")")
    }
    
    private func saveToThesis(_ digest: Digest) {
        print("Saving to thesis: \(digest.title)")
    }
    
    private func shareInsight(_ digest: Digest) {
        print("Sharing insight: \(digest.title)")
    }
}

// MARK: - Digest Enhancement

extension Digest {
    var confidence: Double {
        let baseConfidence = 0.75
        let sourceBonus = min(Double(sourceCount) * 0.02, 0.15)
        return min(baseConfidence + sourceBonus, 0.95)
    }
    
    var tierBadge: String {
        switch summarizationMethod {
        case "appleIntelligence":
            return "✨ Apple Intelligence"
        case "coreML":
            return "🧠 Core ML"
        default:
            return "⚡ On-Device"
        }
    }
}

// MARK: - UIKit Integration for Haptics

#if os(iOS)
import UIKit
#else
struct UINotificationFeedbackGenerator {
    func notificationOccurred(_: Int) {}
}
#endif
