//
//  CelebrationAnimationModifier.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI

public struct CelebrationAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    @State private var showConfetti = false
    @State private var glowIntensity: Double = 0
    @State private var scaleValue: Double = 1.0
    
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
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Haptic feedback
        if config.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: config.hapticStyle)
            impactFeedback.impactOccurred()
        }
        
        // Main animation sequence
        withAnimation(.easeOut(duration: 0.3)) {
            scaleValue = config.scaleEffect
            glowIntensity = 1.0
        }
        
        // Show confetti after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showConfetti = true
            }
        }
        
        // Start fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration * 0.6) {
            withAnimation(.easeInOut(duration: config.duration * 0.4)) {
                glowIntensity = 0
                scaleValue = 1.0
            }
        }
        
        // Hide confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration * 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                showConfetti = false
            }
        }
        
        // Complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
            isAnimating = false
            onAnimationComplete?()
        }
    }
}
