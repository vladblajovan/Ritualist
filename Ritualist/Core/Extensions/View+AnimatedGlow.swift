//
//  View+AnimatedGlow.swift
//  Ritualist
//
//  Created by Claude on 27.11.2025.
//
//  Reusable animated glow effect for views.
//  Creates a flowing, pulsing glow behind content.
//

import SwiftUI
import RitualistCore

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

    @State private var glowPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
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
                .frame(width: glowSize, height: glowSize)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
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
