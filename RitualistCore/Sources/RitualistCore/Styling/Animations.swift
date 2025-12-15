import SwiftUI
import UIKit

// MARK: - Reduced Motion Support
//
// Three functions exist for respecting Reduce Motion preferences:
//
// 1. `animationIfEnabled()` (this file) - Returns Animation? for `.animation()` modifier
//    Usage: `.animation(animationIfEnabled(.spring()), value: state)`
//
// 2. `animateIfAllowed()` (Accessibility.swift) - Wraps `withAnimation` for imperative use
//    Usage: `animateIfAllowed(.easeOut) { isExpanded = true }`
//
// 3. `.reduceMotionAnimation()` (Accessibility.swift) - View modifier alternative to .animation()
//    Usage: `.reduceMotionAnimation(.spring(), value: isExpanded)`
//
// Recommendation: Use `animationIfEnabled()` for animation parameter passing,
// `animateIfAllowed()` for imperative animations, `.reduceMotionAnimation()` for view chains.

/// Returns the animation or nil if reduced motion is preferred
///
/// Use this when passing an Animation to `.animation()` modifier.
/// For imperative animations, use `animateIfAllowed()` from Accessibility.swift.
///
/// Usage: `.animation(animationIfEnabled(.spring()), value: state)`
public func animationIfEnabled(_ animation: Animation) -> Animation? {
    isReduceMotionEnabled ? nil : animation
}

// MARK: - Animation Durations

public enum AnimationDuration {
    public static let fast: Double = 0.2
    public static let medium: Double = 0.3
    public static let slow: Double = 0.5
    public static let verySlow: Double = 1.0

    /// Returns duration or 0 if reduced motion is preferred
    public static func ifEnabled(_ duration: Double) -> Double {
        isReduceMotionEnabled ? 0 : duration
    }
}

public enum SpringAnimation {
    public static let fastResponse: Double = 0.3
    public static let slowResponse: Double = 0.5
    public static let standardDamping: Double = 0.8

    // MARK: - Unified Spring Constants

    /// Standard response time for interactive animations (carousel, toast, cards)
    /// Used across all interactive elements for consistent motion feel
    public static let interactiveResponse: Double = 0.4

    /// Standard damping for interactive animations
    /// 0.7 provides smooth feel without excessive bounce - balances responsiveness and polish
    public static let interactiveDamping: Double = 0.7

    /// Pre-configured standard spring animation for interactive UI elements
    /// Use this for: carousel dismissal, toast animations, card transitions, peek hints
    public static var interactive: Animation {
        .spring(response: interactiveResponse, dampingFraction: interactiveDamping)
    }

    /// Reduced-motion-aware interactive animation
    /// Returns nil when user prefers reduced motion (causes instant state change)
    public static var interactiveIfEnabled: Animation? {
        animationIfEnabled(interactive)
    }
}

// MARK: - Toast Visual Hierarchy Constants

public enum ToastVisualHierarchy {
    /// Scale reduction per stacked toast (6% smaller for each older toast)
    public static let scaleReductionPerIndex: Double = 0.06

    /// Opacity reduction per stacked toast (10% more transparent for each older toast)
    /// Uses ~1.5x ratio with scale for natural depth perception
    public static let opacityReductionPerIndex: Double = 0.10
}