import SwiftUI

// MARK: - Liquid Glass + Neumorphic Theme
// Hybrid design combining iOS 26 Liquid Glass with Neumorphic Soft UI

enum LiquidGlassTheme {
    
    // MARK: - Glass Materials (iOS 26)
    
    enum Glass {
        static var ultraThin: Material { .ultraThinMaterial }
        static var thin: Material { .thinMaterial }
        static var regular: Material { .regularMaterial }
        static var thick: Material { .thickMaterial }
        static var ultraThick: Material { .ultraThickMaterial }
        static var bar: Material { .bar }
    }
    
    // MARK: - Neumorphic Shadow Presets
    
    struct NeumorphicShadows {
        let light: Color
        let dark: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static func elevated(colorScheme: ColorScheme) -> NeumorphicShadows {
            let isDark = colorScheme == .dark
            return NeumorphicShadows(
                light: isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.7),
                dark: isDark ? Color.black.opacity(0.5) : Color.black.opacity(0.15),
                radius: 10,
                x: 6,
                y: 6
            )
        }
        
        static func pressed(colorScheme: ColorScheme) -> NeumorphicShadows {
            let isDark = colorScheme == .dark
            return NeumorphicShadows(
                light: isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.4),
                dark: isDark ? Color.black.opacity(0.6) : Color.black.opacity(0.2),
                radius: 8,
                x: 3,
                y: 3
            )
        }
        
        static func glow(color: Color, intensity: Double = 0.3) -> NeumorphicShadows {
            NeumorphicShadows(
                light: color.opacity(intensity),
                dark: color.opacity(intensity * 0.5),
                radius: 20,
                x: 0,
                y: 0
            )
        }
    }
    
    // MARK: - Background Colors
    
    static func backgroundColor(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.14)
            : Color(red: 0.94, green: 0.95, blue: 0.97)
    }
    
    static func elevatedBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.17)
            : Color(red: 0.96, green: 0.97, blue: 0.98)
    }
    
    static func pressedBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.10, blue: 0.12)
            : Color(red: 0.92, green: 0.93, blue: 0.95)
    }
}

// MARK: - View Modifiers

struct LiquidGlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var isPressed: Bool = false
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                ZStack {
                    // Base glass material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.regularMaterial)
                    
                    // Neumorphic background tint
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isPressed 
                            ? LiquidGlassTheme.pressedBackground(colorScheme: colorScheme)
                            : LiquidGlassTheme.elevatedBackground(colorScheme: colorScheme)
                        )
                        .opacity(0.5)
                }
            )
            .overlay(
                // Highlight border (top-left)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .dark 
                            ? Color.white.opacity(0.15)
                            : Color.white.opacity(0.8),
                        lineWidth: 0.5
                    )
                    .padding(0.5)
            )
            .shadow(
                color: isPressed 
                    ? LiquidGlassTheme.NeumorphicShadows.pressed(colorScheme: colorScheme).dark
                    : LiquidGlassTheme.NeumorphicShadows.elevated(colorScheme: colorScheme).dark,
                radius: isPressed ? 4 : 10,
                x: isPressed ? 3 : 6,
                y: isPressed ? 3 : 6
            )
            .shadow(
                color: isPressed
                    ? LiquidGlassTheme.NeumorphicShadows.pressed(colorScheme: colorScheme).light
                    : LiquidGlassTheme.NeumorphicShadows.elevated(colorScheme: colorScheme).light,
                radius: isPressed ? 4 : 10,
                x: isPressed ? -3 : -6,
                y: isPressed ? -3 : -6
            )
    }
}

struct GlowingButton: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var isActive: Bool = false
    var accentColor: Color = .accentColor
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Base glass capsule
                    Capsule()
                        .fill(.thinMaterial)
                    
                    // Inner glow when active
                    if isActive {
                        Capsule()
                            .fill(accentColor.opacity(0.2))
                            .blur(radius: 8)
                    }
                    
                    // Border
                    Capsule()
                        .stroke(
                            isActive 
                                ? accentColor.opacity(0.5)
                                : (colorScheme == .dark ? Color.white.opacity(0.2) : Color.white.opacity(0.6)),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: isActive 
                    ? accentColor.opacity(0.4)
                    : LiquidGlassTheme.NeumorphicShadows.elevated(colorScheme: colorScheme).dark,
                radius: isActive ? 15 : 8,
                x: 0,
                y: isActive ? 0 : 4
            )
    }
}

struct NeumorphicToggle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isOn: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LiquidGlassTheme.pressedBackground(colorScheme: colorScheme))
                    .shadow(
                        color: LiquidGlassTheme.NeumorphicShadows.pressed(colorScheme: colorScheme).dark,
                        radius: 4,
                        x: 2,
                        y: 2
                    )
                    .shadow(
                        color: LiquidGlassTheme.NeumorphicShadows.pressed(colorScheme: colorScheme).light,
                        radius: 4,
                        x: -2,
                        y: -2
                    )
            )
    }
}

// MARK: - View Extensions

extension View {
    func liquidGlassCard(isPressed: Bool = false, cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidGlassCard(isPressed: isPressed, cornerRadius: cornerRadius))
    }
    
    func glowingButton(isActive: Bool = false, accentColor: Color = .accentColor) -> some View {
        modifier(GlowingButton(isActive: isActive, accentColor: accentColor))
    }
    
    func neumorphicToggle(isOn: Binding<Bool>) -> some View {
        modifier(NeumorphicToggle(isOn: isOn))
    }
}

// MARK: - Preview

#Preview("Liquid Glass + Neumorphic") {
    VStack(spacing: 30) {
        // Elevated card
        Text("Elevated Glass Card")
            .font(.headline)
            .liquidGlassCard(isPressed: false)
        
        // Pressed card
        Text("Pressed Glass Card")
            .font(.headline)
            .liquidGlassCard(isPressed: true)
        
        // Glowing button
        Button("Active Button") {}
            .glowingButton(isActive: true, accentColor: .blue)
        
        // Inactive button
        Button("Inactive Button") {}
            .glowingButton(isActive: false)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
