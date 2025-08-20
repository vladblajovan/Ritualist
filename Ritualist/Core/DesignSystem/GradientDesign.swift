import SwiftUI
import RitualistCore

// MARK: - Gradient Design System for Ritualist
// Colors are now defined in RitualistCore/GradientColors.swift for sharing between app and widget

// MARK: - Animated Gradient Background

struct RitualistGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: gradientStops),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all, edges: .all)
    }
    
    private var gradientStops: [Gradient.Stop] {
        if colorScheme == .dark {
            return [
                .init(color: .ritualistDarkNavy, location: 0.0),
                .init(color: .ritualistDarkPurple, location: 0.5),
                .init(color: .ritualistDarkTeal, location: 1.0)
            ]
        } else {
            return [
                .init(color: .ritualistWarmPeach, location: 0.0),
                .init(color: .ritualistSoftRose, location: 0.25),
                .init(color: .ritualistLilacMist, location: 0.55),
                .init(color: .ritualistSkyAqua, location: 0.80),
                .init(color: .ritualistMintGlow, location: 1.0)
            ]
        }
    }
}

// MARK: - Card Components

struct GlassmorphicCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content
    var cornerRadius: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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

struct SimpleCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content
    var cornerRadius: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(colorScheme == .dark ? 
                      Color(.systemBackground).opacity(0.95) : 
                      Color(.systemBackground).opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.15 : 0.03),
            radius: 4,
            x: 0,
            y: 1
        )
    }
}

// MARK: - View Extension for Easy Integration

extension View {
    /// Adds beautiful gradient background to any view
    func ritualistGradientBackground() -> some View {
        ZStack {
            RitualistGradientBackground()
            self
        }
    }
    
    /// Wraps content in glassmorphic card with gradient
    func glassmorphicCard(cornerRadius: CGFloat = 20) -> some View {
        GlassmorphicCard(cornerRadius: cornerRadius) {
            self
        }
    }
    
    /// Wraps content in simple card with solid background
    func simpleCard(cornerRadius: CGFloat = 20) -> some View {
        SimpleCard(cornerRadius: cornerRadius) {
            self
        }
    }
}