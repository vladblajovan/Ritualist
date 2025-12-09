import SwiftUI
import RitualistCore

/// A simple shadow-based glow effect for indicating state (completion, progress, etc.)
///
/// This differs from `View+AnimatedGlow.swift` which provides animated radial gradient glows:
/// - **ShadowGlow**: Simple shadow-based glow, subtle, for state indication (e.g., completed habits)
/// - **AnimatedGlow**: Complex animated radial gradient, decorative, for visual polish
///
/// Use `shadowGlow()` for functional feedback, `animatedGlow()` for decorative effects.
public struct ShadowGlow: ViewModifier {
    let isGlowing: Bool
    let color: Color
    let radius: CGFloat
    let intensity: Double

    public init(
        isGlowing: Bool,
        color: Color = .green,
        radius: CGFloat = 8,
        intensity: Double = 0.8
    ) {
        self.isGlowing = isGlowing
        self.color = color
        self.radius = radius
        self.intensity = intensity
    }

    public func body(content: Content) -> some View {
        content
            .shadow(
                color: isGlowing ? color.opacity(intensity) : Color.clear,
                radius: isGlowing ? radius : 0,
                x: 0, y: 0
            )
            // Uses animationIfEnabled() which returns nil when Reduce Motion is enabled
            .animation(animationIfEnabled(.easeInOut(duration: AnimationDuration.medium)), value: isGlowing)
    }
}

// MARK: - View Extension

public extension View {
    /// Applies a shadow-based glow effect for state indication
    ///
    /// - Parameters:
    ///   - isGlowing: Whether the glow is active
    ///   - color: The glow color (default: green)
    ///   - radius: The blur radius (default: 8)
    ///   - intensity: The opacity intensity 0-1 (default: 0.8)
    func shadowGlow(
        isGlowing: Bool,
        color: Color = .green,
        radius: CGFloat = 8,
        intensity: Double = 0.8
    ) -> some View {
        modifier(ShadowGlow(
            isGlowing: isGlowing,
            color: color,
            radius: radius,
            intensity: intensity
        ))
    }
}

// MARK: - Convenience Extensions

public extension View {
    /// Green glow for completed state (habits, tasks)
    func completionGlow(isGlowing: Bool) -> some View {
        shadowGlow(
            isGlowing: isGlowing,
            color: .green,
            radius: 12,
            intensity: 0.6
        )
    }

    /// Brand color glow for in-progress state
    func progressGlow(isGlowing: Bool) -> some View {
        shadowGlow(
            isGlowing: isGlowing,
            color: AppColors.brand,
            radius: 8,
            intensity: 0.4
        )
    }
}

// MARK: - Deprecated Aliases

public extension View {
    /// - Warning: Deprecated. Use `shadowGlow()` instead for clarity.
    @available(*, deprecated, renamed: "shadowGlow", message: "Use shadowGlow() for clarity. Will be removed in v2.0")
    func glowEffect(
        isGlowing: Bool,
        color: Color = .green,
        radius: CGFloat = 8,
        intensity: Double = 0.8
    ) -> some View {
        shadowGlow(
            isGlowing: isGlowing,
            color: color,
            radius: radius,
            intensity: intensity
        )
    }
}
