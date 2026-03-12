import Foundation
import NaturalLanguage

/// Tier 3: Extractive Summarization
/// Universal fallback - works on all devices, instant processing
/// Zero ML overhead, algorithmic sentence selection
actor ExtractiveSummarizer {
    static let shared = ExtractiveSummarizer()
    
    private init() {}
    
    /// Summarize text using extractive algorithm
    func summarize(
        _ text: String,
        config: SummarizationConfig = .default
    ) async -> SummarizationResult {
        let startTime = Date()
        
        // 1. Split into sentences
        let sentences = extractSentences(from: text)
        
        guard sentences.count > 1 else {
            return SummarizationResult(
                summary: text,
                tier: .extractive,
                confidence: 1.0,
                processingTime: Date().timeIntervalSince(startTime),
                keyPoints: []
            )
        }
        
        // 2. Score each sentence
        let scoredSentences = sentences.map { sentence in
            (sentence: sentence, score: scoreSentence(sentence, in: text, sentences: sentences))
        }
        
        // 3. Select top sentences
        let topSentences = scoredSentences
            .sorted { $0.score > $1.score }
            .prefix(config.maxSentences)
            .sorted { sentences.firstIndex(of: $0.sentence) ?? 0 < sentences.firstIndex(of: $1.sentence) ?? 0 }
            .map { $0.sentence }
        
        // 4. Join into summary
        let summary = topSentences.joined(separator: " ")
        
        // 5. Extract key points (top 3 scored)
        let keyPoints = scoredSentences
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0.sentence }
        
        return SummarizationResult(
            summary: summary,
            tier: .extractive,
            confidence: calculateConfidence(scoredSentences),
            processingTime: Date().timeIntervalSince(startTime),
            keyPoints: keyPoints
        )
    }
    
    /// Summarize multiple posts
    func summarizePosts(
        _ posts: [Post],
        ticker: String,
        config: SummarizationConfig = .default
    ) async -> Digest {
        let combinedText = posts.map { $0.content }.joined(separator: "\n\n")
        let result = await summarize(combinedText, config: config)
        
        // Calculate sentiment
        let sentiment = analyzeSentiment(posts.map { $0.content }.joined())
        
        return await MainActor.run {
            Digest(
                title: "\(ticker) Community Digest",
                summary: result.summary,
                ticker: ticker,
                sourceCount: posts.count,
                sentiment: sentiment,
                keyPoints: result.keyPoints,
                summarizationMethod: "extractive"
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func extractSentences(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count > 10 { // Filter out very short fragments
                sentences.append(sentence)
            }
            return true
        }
        
        return sentences.isEmpty ? [text] : sentences
    }
    
    private func scoreSentence(_ sentence: String, in text: String, sentences: [String]) -> Double {
        var score = 0.0
        let wordCount = sentence.split(separator: " ").count
        
        // 1. Position score (first and last sentences are important)
        if let index = sentences.firstIndex(of: sentence) {
            if index == 0 {
                score += 3.0 // First sentence
            } else if index == sentences.count - 1 {
                score += 2.0 // Last sentence
            } else if index < 3 {
                score += 1.0 // Early sentences
            }
        }
        
        // 2. Length score (avoid too short or too long)
        if wordCount >= 8 && wordCount <= 25 {
            score += 1.5
        } else if wordCount >= 5 && wordCount <= 35 {
            score += 0.5
        }
        
        // 3. Capital letter density (proper nouns, tickers, acronyms)
        let upperCaseCount = sentence.filter { $0.isUppercase }.count
        let capitalDensity = Double(upperCaseCount) / Double(sentence.count)
        if capitalDensity > 0.15 && capitalDensity < 0.4 {
            score += 1.0
        }
        
        // 4. Financial terms (keyword scoring)
        let financialTerms = [
            "earnings", "revenue", "profit", "growth", "quarter", "fiscal",
            "bullish", "bearish", "target", "price", "dividend", "split",
            "outperform", "underperform", "upgrade", "downgrade",
            "ceo", "cfo", "guidance", "forecast", "estimate"
        ]
        let lowerSentence = sentence.lowercased()
        for term in financialTerms {
            if lowerSentence.contains(term) {
                score += 0.8
            }
        }
        
        // 5. Numeric presence (data points are valuable)
        let numbers = sentence.components(separatedBy: .whitespaces)
            .filter { Double($0) != nil || $0.contains("%") || $0.contains("$") }
        score += Double(numbers.count) * 0.5
        
        // 6. Quote/speech indicators (analyst opinions)
        if sentence.contains("\"") || sentence.contains("said") || sentence.contains("stated") {
            score += 0.5
        }
        
        return score
    }
    
    private func calculateConfidence(_ scoredSentences: [(sentence: String, score: Double)]) -> Double {
        guard scoredSentences.count >= 2 else { return 1.0 }
        
        let sorted = scoredSentences.sorted { $0.score > $1.score }
        let topScore = sorted[0].score
        let secondScore = sorted[1].score
        
        // Higher confidence if top sentence scores significantly better
        let ratio = topScore / (secondScore + 0.1)
        return min(0.95, 0.7 + (ratio * 0.1))
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
        
        // NLTagger returns -1.0 (negative) to 1.0 (positive)
        switch score {
        case ..<(-0.6): return .veryBearish
        case ..<(-0.2): return .bearish
        case 0.2...0.6: return .bullish
        case 0.6...: return .veryBullish
        default: return .neutral
        }
    }
}
