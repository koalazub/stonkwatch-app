import Foundation
import CoreML
import NaturalLanguage

/// Tier 2: Core ML On-Device Summarization
/// Uses lightweight transformer model (~200MB)
/// Downloaded on first use, cached locally
/// Works on all iOS 26 devices
actor CoreMLSummarizer {
    static let shared = CoreMLSummarizer()
    
    private var model: CoreMLModel?
    private let modelURL: URL
    private let defaults = UserDefaults.standard
    private let modelVersionKey = "coreMLModelVersion"
    private let modelDownloadedKey = "coreMLModelDownloaded"
    
    private init() {
        // Model stored in app's documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        modelURL = documentsPath.appendingPathComponent("SummarizationModel.mlmodelc")
    }
    
    // MARK: - Public Properties
    
    var isDownloaded: Bool {
        defaults.bool(forKey: modelDownloadedKey) && FileManager.default.fileExists(atPath: modelURL.path)
    }
    
    var modelSize: String {
        "200 MB" // Estimated size
    }
    
    // MARK: - Summarization
    
    func summarize(
        _ text: String,
        config: SummarizationConfig = .default
    ) async throws -> SummarizationResult {
        guard isDownloaded else {
            throw SummarizationError.modelNotDownloaded
        }
        
        let startTime = Date()
        
        // Load model if needed
        let model = try await loadModel()
        
        // Prepare input
        let input = CoreMLModelInput(text: text)
        
        // Run inference
        let output = try await model.prediction(input: input)
        
        return SummarizationResult(
            summary: output.summary,
            tier: .coreML,
            confidence: 0.85,
            processingTime: Date().timeIntervalSince(startTime),
            keyPoints: []
        )
    }
    
    func summarizePosts(
        _ posts: [Post],
        ticker: String,
        config: SummarizationConfig = .default
    ) async throws -> Digest {
        let combinedText = posts.map { $0.content }.joined(separator: "\n\n")
        let result = try await summarize(combinedText, config: config)
        
        let sentiment = analyzeSentiment(combinedText)
        
        return await MainActor.run {
            Digest(
                title: "\(ticker) ML Digest",
                summary: result.summary,
                ticker: ticker,
                sourceCount: posts.count,
                sentiment: sentiment,
                keyPoints: result.keyPoints,
                summarizationMethod: "coreML"
            )
        }
    }
    
    // MARK: - Model Management
    
    func downloadModel(progress: @escaping (Double) -> Void) async throws {
        // In production, this would download from your server or CDN
        // For now, we'll simulate the download process
        
        let totalBytes: Int64 = 200 * 1024 * 1024 // 200 MB
        var downloadedBytes: Int64 = 0
        
        // Simulate chunked download
        for _ in 0..<20 {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms per chunk
            downloadedBytes += totalBytes / 20
            progress(Double(downloadedBytes) / Double(totalBytes))
        }
        
        // Mark as downloaded
        defaults.set(true, forKey: modelDownloadedKey)
        defaults.set("1.0.0", forKey: modelVersionKey)
    }
    
    func deleteModel() {
        try? FileManager.default.removeItem(at: modelURL)
        defaults.set(false, forKey: modelDownloadedKey)
        model = nil
    }
    
    // MARK: - Private Methods
    
    private func loadModel() async throws -> CoreMLModel {
        if let cached = model {
            return cached
        }
        
        // In production, load compiled Core ML model
        // let model = try await CoreMLModel.load(contentsOf: modelURL)
        let model = CoreMLModel()
        self.model = model
        return model
    }
    
    private func analyzeSentiment(_ text: String) -> SentimentLevel {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )
        
        guard let scoreStr = sentiment?.rawValue,
              let score = Double(scoreStr) else {
            return .neutral
        }
        
        switch score {
        case ..<(-0.6): return .veryBearish
        case ..<(-0.2): return .bearish
        case 0.2...0.6: return .bullish
        case 0.6...: return .veryBullish
        default: return .neutral
        }
    }
}

// MARK: - Placeholder Core ML Model

actor CoreMLModel {
    static func load() async throws -> CoreMLModel {
        CoreMLModel()
    }
    
    func prediction(input: CoreMLModelInput) async throws -> CoreMLModelOutput {
        // In production, this would run actual Core ML inference
        // For now, return a simple extraction
        let sentences = input.text.components(separatedBy: ". ")
        let summary = sentences.prefix(2).joined(separator: ". ") + "."
        return CoreMLModelOutput(summary: "[Core ML] \(summary)")
    }
}

struct CoreMLModelInput {
    let text: String
}

struct CoreMLModelOutput {
    let summary: String
}
