import SwiftUI
import UIKit

enum AppTheme {
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Semantic Colors (Auto-adapts to Light/Dark Mode)
    
    enum Colors {
        /// Primary background - adapts to system appearance
        static var background: Color {
            Color(UIColor.systemBackground)
        }
        
        /// Secondary background for cards and grouped content
        static var secondaryBackground: Color {
            Color(UIColor.secondarySystemBackground)
        }
        
        /// Tertiary background for elevated surfaces
        static var tertiaryBackground: Color {
            Color(UIColor.tertiarySystemBackground)
        }
        
        /// Primary text color
        static var primaryText: Color {
            Color(UIColor.label)
        }
        
        /// Secondary text color
        static var secondaryText: Color {
            Color(UIColor.secondaryLabel)
        }
        
        /// Tertiary text color
        static var tertiaryText: Color {
            Color(UIColor.tertiaryLabel)
        }
        
        /// Accent color for interactive elements
        static var accent: Color {
            Color.accentColor
        }
        
        /// Success/positive color (green)
        static var success: Color {
            Color(UIColor.systemGreen)
        }
        
        /// Error/negative color (red)
        static var error: Color {
            Color(UIColor.systemRed)
        }
        
        /// Warning color (orange/yellow)
        static var warning: Color {
            Color(UIColor.systemOrange)
        }
        
        /// Separator/divider color
        static var separator: Color {
            Color(UIColor.separator)
        }
        
        /// Card background - uses material that adapts
        static var cardBackground: Color {
            Color(UIColor.secondarySystemGroupedBackground)
        }
        
        /// Grouped background (for lists)
        static var groupedBackground: Color {
            Color(UIColor.systemGroupedBackground)
        }
        
        /// Fill colors for subtle backgrounds
        static var fill: Color {
            Color(UIColor.systemFill)
        }
        
        static var secondaryFill: Color {
            Color(UIColor.secondarySystemFill)
        }
        
        /// Gray palette that adapts
        static var gray: Color {
            Color(UIColor.systemGray)
        }
        
        static var gray2: Color {
            Color(UIColor.systemGray2)
        }
        
        static var gray3: Color {
            Color(UIColor.systemGray3)
        }
        
        static var gray4: Color {
            Color(UIColor.systemGray4)
        }
        
        static var gray5: Color {
            Color(UIColor.systemGray5)
        }
        
        static var gray6: Color {
            Color(UIColor.systemGray6)
        }
    }
    
    // MARK: - Sentiment Colors (Dark Mode Optimized)
    
    static func sentimentColor(for level: SentimentLevel) -> Color {
        switch level {
        case .veryBullish:
            // Brighter green in dark mode for visibility
            Color(UIColor.systemGreen)
        case .bullish:
            Color(UIColor.systemGreen).opacity(0.8)
        case .neutral:
            Colors.secondaryText
        case .bearish:
            Color(UIColor.systemRed).opacity(0.8)
        case .veryBearish:
            Color(UIColor.systemRed)
        }
    }
    
    static func priceChangeColor(_ change: Double?) -> Color {
        guard let change else { return Colors.secondaryText }
        if change > 0 { return Colors.success }
        if change < 0 { return Colors.error }
        return Colors.secondaryText
    }
    
    // MARK: - Freshness Colors (Dark Mode Optimized)
    
    static func freshnessColor(_ freshness: ContentFreshness) -> Color {
        switch freshness {
        case .fresh:
            return Color(UIColor.systemGreen)
        case .recent:
            return Color(UIColor.systemBlue)
        case .aging:
            return Color(UIColor.systemOrange)
        case .stale:
            return Colors.secondaryText
        }
    }
}

// MARK: - Typography (Dark Mode Optimized)

extension Font {
    static let digestTitle: Font = .title2.bold()
    static let digestBody: Font = .body
    static let digestCaption: Font = .caption.weight(.medium)
    static let sectionHeader: Font = .headline
    static let tickerSymbol: Font = .subheadline.monospaced().bold()
    static let priceLabel: Font = .title3.monospaced()
}

// MARK: - View Modifiers with Dark Mode Support

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.cardBackground)
                    .shadow(
                        color: colorScheme == .dark 
                            ? Color.black.opacity(0.3)
                            : Color.black.opacity(0.1),
                        radius: colorScheme == .dark ? 8 : 4,
                        x: 0,
                        y: colorScheme == .dark ? 4 : 2
                    )
            )
    }
}

struct AdaptiveCardStyle: ViewModifier {
    let freshness: ContentFreshness
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var backgroundFill: Color {
        switch freshness {
        case .fresh:
            return colorScheme == .dark
                ? Color.green.opacity(0.1)
                : Color.green.opacity(0.05)
        case .recent:
            return AppTheme.Colors.cardBackground
        case .aging:
            return colorScheme == .dark
                ? Color.orange.opacity(0.08)
                : Color.orange.opacity(0.04)
        case .stale:
            return colorScheme == .dark
                ? Color.gray.opacity(0.12)
                : Color.gray.opacity(0.06)
        }
    }
    
    private var borderColor: Color {
        switch freshness {
        case .fresh:
            return Color.green.opacity(colorScheme == .dark ? 0.4 : 0.3)
        case .recent:
            return Color.clear
        case .aging:
            return Color.orange.opacity(colorScheme == .dark ? 0.3 : 0.2)
        case .stale:
            return Color.gray.opacity(colorScheme == .dark ? 0.25 : 0.15)
        }
    }
    
    private var borderWidth: CGFloat {
        freshness == .fresh ? 2 : 1
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func adaptiveCardStyle(freshness: ContentFreshness) -> some View {
        modifier(AdaptiveCardStyle(freshness: freshness))
    }
}

// MARK: - Dark Mode Detection Helper

struct DarkModeAware<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: (Bool) -> Content
    
    init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(colorScheme == .dark)
    }
}
