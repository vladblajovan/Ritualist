import SwiftUI

/// View logic for progress color calculations based on completion rate
/// Separated for testability and reusability across the app
public enum ProgressColorViewLogic {

    // MARK: - Threshold Constants

    /// High completion threshold (80%+) - green color
    public static let highCompletionThreshold: Double = 0.8

    /// Medium completion threshold (50-79%) - orange color
    public static let mediumCompletionThreshold: Double = 0.5

    // MARK: - Color Calculation

    /// Computes the appropriate progress color based on completion rate
    /// - Parameter completionRate: Completion percentage (0.0 to 1.0)
    /// - Returns: Color representing progress level
    ///
    /// Color mapping:
    /// - Green: 80%+ (high completion, including over 100%)
    /// - Orange: 50-79% (medium completion)
    /// - Red: 0-49% (low completion)
    public static func color(for completionRate: Double) -> Color {
        switch completionRate {
        case highCompletionThreshold...:
            return .green
        case mediumCompletionThreshold..<highCompletionThreshold:
            return .orange
        default:
            return .red
        }
    }

    /// Computes CardDesign-based progress color (used in MonthlyCalendar and other components)
    /// - Parameter completionRate: Completion percentage (0.0 to 1.0)
    /// - Returns: CardDesign color representing progress level
    ///
    /// This variant uses CardDesign tokens for consistency with calendar components
    public static func cardDesignColor(for completionRate: Double) -> Color {
        switch completionRate {
        case 1.0:
            return CardDesign.progressGreen
        case highCompletionThreshold..<1.0:
            return CardDesign.progressOrange
        case mediumCompletionThreshold..<highCompletionThreshold:
            return CardDesign.progressRed.opacity(0.6)
        default:
            return CardDesign.secondaryBackground
        }
    }
}
