import SwiftUI

@Observable
final class AppSettings {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    private let appearanceKey = "appAppearance"
    private let summarizationTierKey = "summarizationTier"
    
    private(set) var appearance: AppAppearance
    private(set) var summarizationTier: SummarizationTier
    
    var colorScheme: ColorScheme? {
        switch appearance {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    private init() {
        // Load appearance
        if let rawValue = defaults.string(forKey: appearanceKey),
           let value = AppAppearance(rawValue: rawValue) {
            self.appearance = value
        } else {
            self.appearance = .system
        }
        
        // Load summarization tier
        if let rawValue = defaults.string(forKey: summarizationTierKey),
           let value = SummarizationTier(rawValue: rawValue) {
            self.summarizationTier = value
        } else {
            self.summarizationTier = .auto
        }
    }
    
    func setAppearance(_ newAppearance: AppAppearance) {
        appearance = newAppearance
        defaults.set(newAppearance.rawValue, forKey: appearanceKey)
    }
    
    func setSummarizationTier(_ tier: SummarizationTier) {
        summarizationTier = tier
        defaults.set(tier.rawValue, forKey: summarizationTierKey)
    }
}

enum AppAppearance: String, CaseIterable, Sendable {
    case system
    case light
    case dark
    
    var label: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}
