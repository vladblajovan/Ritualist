//
//  View+AnimatedGlow.swift
//  Ritualist
//
//  Created by Claude on 27.11.2025.
//
//  Reusable animated glow effect for views.
//  Creates a flowing, pulsing glow behind content.
//
//  Accessibility: Respects "Reduce Motion" setting (WCAG 2.3.3)
//

import SwiftUI
import RitualistCore

// MARK: - Reduce Motion Support

/// Checks if reduce motion should be enabled, respecting both system settings and test overrides.
@MainActor
private var shouldReduceMotion: Bool {
    #if DEBUG
    if LaunchArgument.reduceMotion.isActive {
        return true
    }
    #endif
    return UIAccessibility.isReduceMotionEnabled
}

// MARK: - View Extension

extension View {
    /// Adds an animated flowing glow effect behind the view.
    /// - Parameters:
    ///   - color: The color of the glow (default: AppColors.brand)
    ///   - glowSize: The size of the glow area (default: 160)
    ///   - intensity: The intensity of the glow from 0 to 1 (default: 0.5)
    ///   - duration: Animation cycle duration in seconds (default: 1.5)
    func animatedGlow(
        color: Color = AppColors.brand,
        glowSize: CGFloat = 160,
        intensity: CGFloat = 0.5,
        duration: Double = 1.5
    ) -> some View {
        modifier(AnimatedGlowModifier(
            color: color,
            glowSize: glowSize,
            intensity: intensity,
            duration: duration
        ))
    }
}

// MARK: - View Modifier

private struct AnimatedGlowModifier: ViewModifier {
    let color: Color
    let glowSize: CGFloat
    let intensity: CGFloat
    let duration: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowPhase: CGFloat = 0

    /// Whether to show static glow (no animation)
    private var isReduceMotionEnabled: Bool {
        reduceMotion || shouldReduceMotion
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isReduceMotionEnabled {
                        // Static glow for reduce motion - single layer, no animation
                        staticGlowLayer
                    } else {
                        // Animated glow layers
                        animatedGlowLayers
                    }
                }
                .frame(width: glowSize, height: glowSize)
            )
            .onAppear {
                guard !isReduceMotionEnabled else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            }
    }

    // MARK: - Static Glow (Reduce Motion)

    private var staticGlowLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(intensity * 0.7),
                        color.opacity(intensity * 0.3),
                        color.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: glowSize * 0.3,
                    endRadius: glowSize * 0.65
                )
            )
            .blur(radius: glowSize * 0.125)
    }

    // MARK: - Animated Glow

    private var animatedGlowLayers: some View {
        Group {
            // Primary animated glow layer
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(intensity),
                            color.opacity(intensity * 0.4),
                            color.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: glowSize * 0.3,
                        endRadius: glowSize * 0.6
                    )
                )
                .scaleEffect(1.0 + glowPhase * 0.3)
                .opacity(0.8 - glowPhase * 0.3)
                .blur(radius: glowSize * 0.125)

            // Secondary layer for depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(intensity * 0.8),
                            color.opacity(intensity * 0.2),
                            color.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: glowSize * 0.35,
                        endRadius: glowSize * 0.7
                    )
                )
                .scaleEffect(1.2 + (1 - glowPhase) * 0.2)
                .opacity(0.6 - (1 - glowPhase) * 0.2)
                .blur(radius: glowSize * 0.15)
        }
    }
}

// MARK: - Preview

#Preview("Animated Glow") {
    VStack(spacing: 40) {
        // Default glow
        Circle()
            .fill(AppColors.brand)
            .frame(width: 100, height: 100)
            .animatedGlow()

        // Custom color and size
        RoundedRectangle(cornerRadius: 20)
            .fill(.purple)
            .frame(width: 80, height: 80)
            .animatedGlow(color: .purple, glowSize: 140)

        // High intensity
        Circle()
            .fill(.orange)
            .frame(width: 60, height: 60)
            .animatedGlow(color: .orange, glowSize: 120, intensity: 0.7)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
}
