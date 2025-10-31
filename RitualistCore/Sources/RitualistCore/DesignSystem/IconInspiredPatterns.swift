import SwiftUI

// MARK: - Icon-Inspired Visual Patterns

/// Circular ring pattern overlay inspired by the app icon background
///
/// The app icon features subtle concentric circular rings that create depth.
/// This component recreates that visual signature for use in cards and backgrounds.
///
/// Performance: Lightweight overlay with blur for subtle effect
/// Usage: Apply as overlay to cards, backgrounds, or containers
@available(iOS 13.0, *)
public struct CircularRingsPattern: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Intensity of the ring effect (0.0 to 1.0)
    public let intensity: CGFloat

    /// Number of concentric rings to draw
    public let ringCount: Int

    /// Optional center offset (defaults to center)
    public let centerOffset: CGPoint?

    public init(
        intensity: CGFloat = 0.3,
        ringCount: Int = 3,
        centerOffset: CGPoint? = nil
    ) {
        self.intensity = intensity
        self.ringCount = ringCount
        self.centerOffset = centerOffset
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<ringCount, id: \.self) { index in
                    Circle()
                        .stroke(
                            ringColor.opacity(ringOpacity(for: index)),
                            lineWidth: strokeWidth(for: index)
                        )
                        .frame(
                            width: ringSize(for: index, in: geometry.size),
                            height: ringSize(for: index, in: geometry.size)
                        )
                        .position(
                            x: (centerOffset?.x ?? geometry.size.width / 2),
                            y: (centerOffset?.y ?? geometry.size.height / 2)
                        )
                }
            }
            .blur(radius: blurRadius)
            .allowsHitTesting(false)  // Don't intercept touches
        }
    }

    // MARK: - Visual Properties

    private var ringColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private func ringOpacity(for index: Int) -> CGFloat {
        let baseOpacity = colorScheme == .dark ? 0.12 : 0.06
        // Fade out as rings get larger
        return baseOpacity * intensity / CGFloat(index + 1)
    }

    private func strokeWidth(for index: Int) -> CGFloat {
        // Thicker strokes for outer rings
        return 1.5 + CGFloat(index) * 0.5
    }

    private func ringSize(for index: Int, in size: CGSize) -> CGFloat {
        let baseSize = min(size.width, size.height)
        // Each ring is progressively larger
        return baseSize * CGFloat(index + 1) * 0.35
    }

    private var blurRadius: CGFloat {
        // More blur in dark mode for softer glow effect
        return colorScheme == .dark ? 25 : 20
    }
}

// MARK: - Checkmark Success Gradient

/// Animated checkmark gradient inspired by the app icon's checkmark
///
/// Light mode: White → Gold (matches icon)
/// Dark mode: Yellow-Lime → Orange (matches icon)
///
/// Usage: Apply to checkmarks, success indicators, completion states
@available(iOS 13.0, *)
public struct IconCheckmarkGradient {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var gradient: LinearGradient {
        if colorScheme == .dark {
            // Dark mode: Yellow-Lime → Orange (icon checkmark)
            return LinearGradient(
                colors: [Color.ritualistYellowLime, Color.ritualistOrange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Light mode: White → Gold (icon checkmark)
            return LinearGradient(
                colors: [Color.ritualistWhite, Color.ritualistGold],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Progress Ring Gradient

/// Progress indicator gradient inspired by the app icon's background
///
/// Always uses Cyan → Blue regardless of light/dark mode
///
/// Usage: Apply to progress rings, progress bars, completion indicators
@available(iOS 13.0, *)
public struct IconProgressGradient {
    public init() {}

    public var gradient: LinearGradient {
        // Icon background gradient (light mode cyan → blue)
        LinearGradient(
            colors: [Color.ritualistCyan, Color.ritualistBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - View Extensions

@available(iOS 13.0, *)
public extension View {
    /// Adds circular ring pattern overlay (icon signature depth effect)
    ///
    /// - Parameters:
    ///   - intensity: Ring visibility (0.0 to 1.0, default 0.3)
    ///   - ringCount: Number of concentric rings (default 3)
    ///   - centerOffset: Optional center offset for asymmetric effect
    func iconRingsOverlay(
        intensity: CGFloat = 0.3,
        ringCount: Int = 3,
        centerOffset: CGPoint? = nil
    ) -> some View {
        overlay(
            CircularRingsPattern(
                intensity: intensity,
                ringCount: ringCount,
                centerOffset: centerOffset
            )
        )
    }

    /// Applies icon checkmark gradient (context-aware: light/dark mode)
    ///
    /// Usage: Image(systemName: "checkmark").foregroundStyle(iconCheckmarkGradient())
    @ViewBuilder
    func iconCheckmarkGradient() -> some View {
        let gradient = IconCheckmarkGradient().gradient
        foregroundStyle(gradient)
    }

    /// Applies icon progress gradient (cyan → blue)
    ///
    /// Usage: Circle().stroke(iconProgressGradient(), lineWidth: 4)
    func iconProgressGradient() -> LinearGradient {
        IconProgressGradient().gradient
    }
}
