//
//  BestStreakAnimationView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import SwiftUI

// MARK: - Animation Configuration

public struct CelebrationAnimationConfig {
    public let duration: Double
    public let scaleEffect: Double
    public let glowRadius: Double
    public let glowColor: Color
    public let confettiCount: Int
    public let confettiColors: [Color]
    public let hapticFeedback: Bool
    public let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    public init(
        duration: Double = 2.0,
        scaleEffect: Double = 1.15,
        glowRadius: Double = 20.0,
        glowColor: Color = .yellow,
        confettiCount: Int = 8,
        confettiColors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue, .green],
        hapticFeedback: Bool = true,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .heavy
    ) {
        self.duration = duration
        self.scaleEffect = scaleEffect
        self.glowRadius = glowRadius
        self.glowColor = glowColor
        self.confettiCount = confettiCount
        self.confettiColors = confettiColors
        self.hapticFeedback = hapticFeedback
        self.hapticStyle = hapticStyle
    }
    
    // Preset configurations for different contexts
    public static let bestStreak = CelebrationAnimationConfig()
    
    public static let levelUp = CelebrationAnimationConfig(
        duration: 1.8,
        scaleEffect: 1.2,
        glowColor: .blue,
        confettiColors: [.blue, .cyan, .indigo, .purple],
        hapticStyle: .medium
    )
    
    public static let achievement = CelebrationAnimationConfig(
        duration: 2.2,
        scaleEffect: 1.1,
        glowColor: .green,
        confettiCount: 12,
        confettiColors: [.green, .mint, .yellow, .orange]
    )
    
    public static let milestone = CelebrationAnimationConfig(
        duration: 2.5,
        scaleEffect: 1.25,
        glowColor: .purple,
        confettiCount: 15,
        
        confettiColors: [.purple, .pink, .red, .orange, .yellow],
        hapticStyle: .heavy
    )
    
    public static let subtle = CelebrationAnimationConfig(
        duration: 1.5,
        scaleEffect: 1.08,
        glowRadius: 10.0,
        glowColor: .gray,
        confettiCount: 5,
        confettiColors: [.gray, .secondary],
        hapticFeedback: false
    )
}

// MARK: - Celebration Animation Modifier

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

// MARK: - Confetti Particle

private struct ConfettiParticle: View {
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    private let isVisible: Bool
    private let delay: Double
    private let angle: Double
    private let colors: [Color]
    
    init(isVisible: Bool, delay: Double, angle: Double, colors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue, .green]) {
        self.isVisible = isVisible
        self.delay = delay
        self.angle = angle
        self.colors = colors
    }
    
    var body: some View {
        Circle()
            .fill(colors.randomElement() ?? .yellow)
            .frame(width: 8, height: 8)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onChange(of: isVisible) { _, newValue in
                if newValue {
                    startParticleAnimation()
                } else {
                    resetParticle()
                }
            }
    }
    
    private func startParticleAnimation() {
        let distance: Double = 80
        let targetX = cos(angle * .pi / 180) * distance
        let targetY = sin(angle * .pi / 180) * distance
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.6)) {
                offset = CGSize(width: targetX, height: targetY)
                rotation = Double.random(in: 0...360)
                opacity = 1.0
            }
            
            // Fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.4)) {
                    opacity = 0
                }
            }
        }
    }
    
    private func resetParticle() {
        offset = .zero
        rotation = 0
        opacity = 0
    }
}

// MARK: - Convenience View Extension

public extension View {
    /// Apply celebration animation to any view
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
    
    /// Convenience method for best streak animation (backward compatibility)
    func bestStreakAnimation(
        isTriggered: Bool,
        config: CelebrationAnimationConfig = .bestStreak,
        onAnimationComplete: (() -> Void)? = nil
    ) -> some View {
        celebrationAnimation(
            isTriggered: isTriggered,
            config: config,
            onAnimationComplete: onAnimationComplete
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        VStack {
            Text("15")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            Text("Best")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .celebrationAnimation(isTriggered: true, config: .bestStreak)
        
        Button("Trigger Animation") {
            // Animation will be triggered by the isTriggered binding
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}
