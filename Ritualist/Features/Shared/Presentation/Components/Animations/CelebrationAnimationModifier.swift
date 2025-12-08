//
//  CelebrationAnimationModifier.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import RitualistCore

public struct CelebrationAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    @State private var showConfetti = false
    @State private var glowIntensity: Double = 0
    @State private var scaleValue: Double = 1.0
    @State private var animationTask: Task<Void, Never>?

    private let isTriggered: Bool
    private let config: CelebrationAnimationConfig
    private let onAnimationComplete: (() -> Void)?
    
    public init(
        isTriggered: Bool,
        config: CelebrationAnimationConfig = .bestStreak,
        onAnimationComplete: (() -> Void)? = nil
    ) {
        self.isTriggered = isTriggered
        self.config = config
        self.onAnimationComplete = onAnimationComplete
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(scaleValue)
            .background(
                // Glow effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(config.glowColor.opacity(glowIntensity * 0.3))
                    .blur(radius: config.glowRadius * glowIntensity)
                    .scaleEffect(1.2)
            )
            .overlay(
                // Confetti particles
                ForEach(0..<config.confettiCount, id: \.self) { index in
                    ConfettiParticle(
                        isVisible: showConfetti,
                        delay: Double(index) * 0.1,
                        angle: Double(index) * (360.0 / Double(config.confettiCount)),
                        colors: config.confettiColors
                    )
                }
            )
            .onChange(of: isTriggered) { _, newValue in
                if newValue && !isAnimating {
                    startAnimation()
                }
            }
            .onDisappear {
                // Cancel any pending animation tasks when view disappears
                animationTask?.cancel()
            }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        // Haptic feedback (always provide tactile feedback regardless of motion setting)
        if config.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: config.hapticStyle)
            impactFeedback.impactOccurred()
        }

        // Skip visual animations if user prefers reduced motion
        if isReduceMotionEnabled {
            // Just complete immediately with haptic feedback
            animationTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                isAnimating = false
                onAnimationComplete?()
            }
            return
        }

        // Run animation sequence with cancellation support
        animationTask = Task { @MainActor in
            // Main animation sequence
            withAnimation(.easeOut(duration: 0.3)) {
                scaleValue = config.scaleEffect
                glowIntensity = 1.0
            }

            // Show confetti after a slight delay
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                showConfetti = true
            }

            // Start fade out
            try? await Task.sleep(for: .milliseconds(Int(config.duration * 400))) // 0.6 - 0.2 = 0.4
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: config.duration * 0.4)) {
                glowIntensity = 0
                scaleValue = 1.0
            }

            // Hide confetti
            try? await Task.sleep(for: .milliseconds(Int(config.duration * 200))) // 0.8 - 0.6 = 0.2
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.3)) {
                showConfetti = false
            }

            // Complete animation
            try? await Task.sleep(for: .milliseconds(Int(config.duration * 200))) // 1.0 - 0.8 = 0.2
            guard !Task.isCancelled else { return }
            isAnimating = false
            onAnimationComplete?()
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Adds a celebration animation with confetti particles
    /// - Parameters:
    ///   - isTriggered: When true, triggers the animation
    ///   - config: Animation configuration (colors, intensity, duration)
    ///   - onAnimationComplete: Called when the animation finishes
    func celebrationAnimation(
        isTriggered: Bool,
        config: CelebrationAnimationConfig = .bestStreak,
        onAnimationComplete: (() -> Void)? = nil
    ) -> some View {
        modifier(CelebrationAnimationModifier(
            isTriggered: isTriggered,
            config: config,
            onAnimationComplete: onAnimationComplete
        ))
    }
}
