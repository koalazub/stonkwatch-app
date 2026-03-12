import Foundation
import NaturalLanguage

/// Three-tier AI summarization system
/// Tier 1: Apple Intelligence (iOS 26+, iPhone 15 Pro+)
/// Tier 2: Core ML On-Device Model (All iOS 26 devices)
/// Tier 3: Extractive Algorithm (Universal fallback)
enum SummarizationTier: String, CaseIterable, Sendable {
    case auto = "auto"
    case appleIntelligence = "appleIntelligence"
    case coreML = "coreML"
    case extractive = "extractive"
    
    var displayName: String {
        switch self {
        case .auto:
            return "Auto-Select (Recommended)"
        case .appleIntelligence:
            return "Apple Intelligence"
        case .coreML:
            return "Core ML Model"
        case .extractive:
            return "Fast Extractive"
        }
    }
    
    var icon: String {
        switch self {
        case .auto:
            return "wand.and.stars"
        case .appleIntelligence:
            return "sparkles"
        case .coreML:
            return "brain.head.profile"
        case .extractive:
            return "bolt.fill"
        }
    }
    
    var description: String {
        switch self {
        case .auto:
            return "Automatically uses the best available AI"
        case .appleIntelligence:
            return "Native Apple AI - highest quality"
        case .coreML:
            return "On-device transformer model"
        case .extractive:
            return "Instant algorithmic summary"
        }
    }
    
    var badge: String {
        switch self {
        case .auto:
            return "✨"
        case .appleIntelligence:
            return "✨ Apple Intelligence"
        case .coreML:
            return "🧠 Core ML"
        case .extractive:
            return "⚡ Extractive"
        }
    }
}

/// Configuration for summarization requests
struct SummarizationConfig: Sendable {
    let tone: SummarizationTone
    let length: SummarizationLength
    let maxSentences: Int
    
    nonisolated static let `default` = SummarizationConfig(
        tone: .neutral,
        length: .medium,
        maxSentences: 3
    )
    
    nonisolated static let briefing = SummarizationConfig(
        tone: .neutral,
        length: .short,
        maxSentences: 2
    )
    
    nonisolated static let deepDive = SummarizationConfig(
        tone: .professional,
        length: .long,
        maxSentences: 5
    )
}

enum SummarizationTone: String, CaseIterable {
    case neutral
    case professional
    case casual
    case urgent
    
    var displayName: String {
        switch self {
        case .neutral: return "Neutral"
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .urgent: return "Urgent"
        }
    }
}

enum SummarizationLength: String, CaseIterable {
    case short
    case medium
    case long
    
    var displayName: String {
        switch self {
        case .short: return "Brief"
        case .medium: return "Standard"
        case .long: return "Detailed"
        }
    }
    
    var maxWords: Int {
        switch self {
        case .short: return 50
        case .medium: return 100
        case .long: return 200
        }
    }
}

/// Result from any summarization tier
struct SummarizationResult {
    let summary: String
    let tier: SummarizationTier
    let confidence: Double
    let processingTime: TimeInterval
    let keyPoints: [String]
}

/// Model download status for Core ML tier
enum ModelDownloadStatus: Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(size: String)
    case failed(Error)
}

/// Error types for summarization
enum SummarizationError: Error {
    case tierNotAvailable
    case modelNotDownloaded
    case downloadFailed(Error)
    case processingFailed(Error)
    case noContentToSummarize
    case deviceNotSupported
}
