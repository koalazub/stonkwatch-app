import Foundation

/// Coordinator service that manages all three summarization tiers
/// Automatically selects best available or uses user preference
actor SummarizationService {
    static let shared = SummarizationService()
    
    private let extractive = ExtractiveSummarizer.shared
    private let coreML = CoreMLSummarizer.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get current tier based on settings and availability
    func getCurrentTier() async -> SummarizationTier {
        let preferred = await MainActor.run {
            AppSettings.shared.summarizationTier
        }
        
        switch preferred {
        case .auto:
            return await determineBestTier()
        case .appleIntelligence:
            let isAvailable = await AppleIntelligenceSummarizer.shared.isAvailable
            return isAvailable ? .appleIntelligence : await determineBestTier()
        case .coreML:
            return await determineBestTier()
        case .extractive:
            return .extractive
        }
    }
    
    /// Check tier availability
    func isTierAvailable(_ tier: SummarizationTier) async -> Bool {
        switch tier {
        case .auto:
            return true
        case .appleIntelligence:
            return await AppleIntelligenceSummarizer.shared.isAvailable
        case .coreML:
            return true
        case .extractive:
            return true
        }
    }
    
    /// Summarize posts using appropriate tier
    func summarizePosts(
        _ posts: [Post],
        ticker: String,
        config: SummarizationConfig = .default
    ) async -> Digest {
        let tier = await getCurrentTier()
        
        do {
            switch tier {
            case .appleIntelligence:
                return try await AppleIntelligenceSummarizer.shared.summarizePosts(posts, ticker: ticker, config: config)
            case .coreML:
                return try await coreML.summarizePosts(posts, ticker: ticker, config: config)
            case .extractive, .auto:
                return await extractive.summarizePosts(posts, ticker: ticker, config: config)
            }
        } catch {
            // Fallback to extractive on any error
            return await extractive.summarizePosts(posts, ticker: ticker, config: config)
        }
    }
    
    /// Force specific tier (for testing)
    func summarizePosts(
        _ posts: [Post],
        ticker: String,
        forcing tier: SummarizationTier,
        config: SummarizationConfig = .default
    ) async throws -> Digest {
        switch tier {
        case .appleIntelligence:
            let isAvailable = await AppleIntelligenceSummarizer.shared.isAvailable
            guard isAvailable else {
                throw SummarizationError.tierNotAvailable
            }
            return try await AppleIntelligenceSummarizer.shared.summarizePosts(posts, ticker: ticker, config: config)
            
        case .coreML:
            return try await coreML.summarizePosts(posts, ticker: ticker, config: config)
            
        case .extractive:
            return await extractive.summarizePosts(posts, ticker: ticker, config: config)
            
        case .auto:
            return await summarizePosts(posts, ticker: ticker, config: config)
        }
    }
    
    /// Summarize single text
    func summarize(
        _ text: String,
        config: SummarizationConfig = .default
    ) async -> SummarizationResult {
        let tier = await getCurrentTier()
        
        do {
            switch tier {
            case .appleIntelligence:
                return try await AppleIntelligenceSummarizer.shared.summarize(text, config: config)
            case .coreML:
                return try await coreML.summarize(text, config: config)
            case .extractive, .auto:
                return await extractive.summarize(text, config: config)
            }
        } catch {
            // Fallback to extractive
            return await extractive.summarize(text, config: config)
        }
    }
    
    // MARK: - Model Management
    
    func isCoreMLModelDownloaded() async -> Bool {
        await coreML.isDownloaded
    }
    
    func downloadCoreMLModel(progress: @escaping (Double) -> Void) async throws {
        try await coreML.downloadModel(progress: progress)
    }
    
    func deleteCoreMLModel() async {
        await coreML.deleteModel()
    }
    
    // MARK: - Private Methods
    
    private func determineBestTier() async -> SummarizationTier {
        let isAppleIntelAvailable = await AppleIntelligenceSummarizer.shared.isAvailable
        if isAppleIntelAvailable {
            return .appleIntelligence
        }
        // For now, always fall back to extractive (CoreML check would be async)
        return .extractive
    }
}
