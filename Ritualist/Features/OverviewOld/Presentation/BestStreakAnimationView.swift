//
//  BestStreakAnimationView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import SwiftUI

// MARK: - Animation Configuration



// MARK: - Celebration Animation Modifier



// MARK: - Confetti Particle



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
