import SwiftUI

/// View logic for inspiration card style computation
/// Separated for testability and reusability across the app
public enum InspirationStyleViewLogic {

    /// Context containing all information needed to compute inspiration card style
    public struct StyleContext {
        public let completionPercentage: Double
        public let timeOfDay: TimeOfDay

        public init(completionPercentage: Double, timeOfDay: TimeOfDay) {
            self.completionPercentage = completionPercentage
            self.timeOfDay = timeOfDay
        }
    }

    /// Gradient type identifier for testability
    public enum GradientType: Equatable {
        case perfect
        case strong
        case midway
        case morning
        case noon
        case evening
    }

    /// Complete style information for inspiration card display
    public struct Style {
        public let gradient: LinearGradient
        public let gradientType: GradientType
        public let iconName: String
        public let accentColor: Color

        public init(gradient: LinearGradient, gradientType: GradientType, iconName: String, accentColor: Color) {
            self.gradient = gradient
            self.gradientType = gradientType
            self.iconName = iconName
            self.accentColor = accentColor
        }
    }

    // MARK: - Style Computation

    /// Computes the appropriate style based on completion percentage and time of day
    /// - Parameter context: Style context with completion and time information
    /// - Returns: Complete style configuration (gradient, icon, color)
    ///
    /// Priority rules:
    /// 1. Completion >= 100%: Perfect day celebration (yellow-lime gradient)
    /// 2. Completion >= 75%: Strong progress (cyan-blue gradient)
    /// 3. Completion >= 50%: Midway encouragement (gold gradient)
    /// 4. Completion < 50%: Time-based motivation (morning/noon/evening)
    public static func computeStyle(for context: StyleContext) -> Style {

        // Progress-based styling (takes priority)
        if context.completionPercentage >= 1.0 {
            // Perfect day celebration
            return Style(
                gradient: GradientTokens.inspirationPerfect,
                gradientType: .perfect,
                iconName: "party.popper.fill",
                accentColor: .green
            )
        } else if context.completionPercentage >= 0.75 {
            // Strong progress celebration
            return Style(
                gradient: GradientTokens.inspirationStrong,
                gradientType: .strong,
                iconName: "flame.fill",
                accentColor: .blue
            )
        } else if context.completionPercentage >= 0.5 {
            // Midway encouragement
            return Style(
                gradient: GradientTokens.inspirationMidway,
                gradientType: .midway,
                iconName: "bolt.fill",
                accentColor: .orange
            )
        } else {
            // Time-based motivation (< 50% completion)
            return timeBasedStyle(for: context.timeOfDay)
        }
    }

    // MARK: - Time-Based Styling

    /// Computes style based on time of day (used when completion < 50%)
    /// - Parameter timeOfDay: Current time period
    /// - Returns: Time-appropriate style configuration
    private static func timeBasedStyle(for timeOfDay: TimeOfDay) -> Style {
        switch timeOfDay {
        case .morning:
            return Style(
                gradient: GradientTokens.inspirationMorning,
                gradientType: .morning,
                iconName: "sunrise.fill",
                accentColor: .pink
            )
        case .noon:
            return Style(
                gradient: GradientTokens.inspirationNoon,
                gradientType: .noon,
                iconName: "sun.max.fill",
                accentColor: .indigo
            )
        case .evening:
            return Style(
                gradient: GradientTokens.inspirationEvening,
                gradientType: .evening,
                iconName: "moon.stars.fill",
                accentColor: .purple
            )
        }
    }
}
