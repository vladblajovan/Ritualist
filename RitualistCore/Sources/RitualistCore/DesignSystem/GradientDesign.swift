import SwiftUI

// MARK: - Animated Gradient Background

public struct RitualistGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        // PERFORMANCE: Simplified 3-color gradient for smooth scrolling
        // 5 color stops were causing significant GPU overhead during scroll
        // NOTE: .drawingGroup() causes safe area rendering issues - removed
        LinearGradient(
            colors: colorScheme == .dark ? darkColors : lightColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all, edges: .all)
    }

    // PERFORMANCE: Use simple color arrays instead of Gradient.Stop for faster rendering
    // DESIGN: Icon-inspired gradients - matches app icon background
    private var lightColors: [Color] {
        [
            .ritualistCyan,        // Icon left: Cyan
            .ritualistBlue,        // Icon right: Blue
            .ritualistLightBlue    // Subtle variation for depth
        ]
    }

    private var darkColors: [Color] {
        [
            .ritualistDeepNavy,    // Deep navy for depth
            .ritualistDarkNavy,    // Icon background: Dark navy
            .ritualistMidNavy      // Mid navy for variation
        ]
    }
}

// MARK: - Card Components

public struct GlassmorphicCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content
    var cornerRadius: CGFloat = 20

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        // PERFORMANCE: Use thin material instead of ultraThin for better scroll performance
        // ultraThinMaterial causes expensive blur recalculations on every scroll frame
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(colorScheme == .dark ? 0.2 : 0.3), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 6,
            x: 0,
            y: 2
        )
        .compositingGroup()
    }
}

// MARK: - View Extension for Easy Integration

public extension View {
    /// Adds beautiful gradient background to any view
    public func ritualistGradientBackground() -> some View {
        ZStack {
            RitualistGradientBackground()
            self
        }
    }

    /// Wraps content in glassmorphic card with gradient
    public func glassmorphicCard(cornerRadius: CGFloat = 20) -> some View {
        GlassmorphicCard(cornerRadius: cornerRadius) {
            self
        }
    }
}
