//
//  CelebrationAnimationConfig.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI

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
