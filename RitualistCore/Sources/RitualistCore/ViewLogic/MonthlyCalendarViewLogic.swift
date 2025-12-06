import SwiftUI
import Foundation
import RitualistCore

/// View logic for monthly calendar day display calculations
/// Separated for testability and reusability across the app
public enum MonthlyCalendarViewLogic {

    /// Context containing all information needed to compute day display properties
    public struct DayContext {
        public let date: Date
        public let completion: Double
        public let today: Date
        public let currentMonth: Int
        public let calendar: Calendar

        public init(date: Date, completion: Double, today: Date, currentMonth: Int, calendar: Calendar) {
            self.date = date
            self.completion = completion
            self.today = today
            self.currentMonth = currentMonth
            self.calendar = calendar
        }

        /// Whether this day is today (in the calendar's timezone)
        public var isToday: Bool {
            // Compare day/month/year components explicitly using the calendar's timezone
            let tz = calendar.timeZone
            let dateComponents = calendar.dateComponents(in: tz, from: date)
            let todayComponents = calendar.dateComponents(in: tz, from: Date())
            return dateComponents.year == todayComponents.year &&
                   dateComponents.month == todayComponents.month &&
                   dateComponents.day == todayComponents.day
        }

        /// Whether this day is in the future (relative to today in the calendar's timezone)
        public var isFuture: Bool {
            // Compare day/month/year components explicitly using the calendar's timezone
            let tz = calendar.timeZone
            let dateComponents = calendar.dateComponents(in: tz, from: date)
            let todayComponents = calendar.dateComponents(in: tz, from: Date())

            // Safe unwrapping - return false (not future) if any component is nil
            guard let dateYear = dateComponents.year,
                  let dateMonth = dateComponents.month,
                  let dateDay = dateComponents.day,
                  let todayYear = todayComponents.year,
                  let todayMonth = todayComponents.month,
                  let todayDay = todayComponents.day else {
                return false
            }

            if dateYear > todayYear { return true }
            if dateYear < todayYear { return false }
            if dateMonth > todayMonth { return true }
            if dateMonth < todayMonth { return false }
            return dateDay > todayDay
        }

        /// Whether this day belongs to the current viewing month
        public var isCurrentMonth: Bool {
            let tz = calendar.timeZone
            let dateMonth = calendar.dateComponents(in: tz, from: date).month
            return dateMonth == currentMonth
        }
    }

    // MARK: - Background Color Logic

    /// Computes the background color based on completion percentage and date context
    /// Matches CircularProgressView.adaptiveProgressColors thresholds
    /// - Parameter context: Day context with date and completion information
    /// - Returns: Background color for the day circle
    public static func backgroundColor(for context: DayContext) -> Color {
        // Future dates get neutral background
        if context.isFuture {
            return CardDesign.secondaryBackground
        }

        // Past/today dates get color based on completion
        // Matches gradient thresholds: 0-50% red, 50-80% orange, 80-100% green, 100% full green
        if context.completion >= 1.0 {
            return CardDesign.progressGreen
        }
        if context.completion >= 0.8 {
            return CardDesign.progressGreen
        }
        if context.completion >= 0.5 {
            return CardDesign.progressOrange
        }
        if context.completion > 0 {
            return CardDesign.progressRed.opacity(0.6)
        }

        // No progress
        return CardDesign.secondaryBackground
    }

    // MARK: - Text Color Logic

    /// Computes the text color ensuring readability based on background
    /// - Parameter context: Day context with date and completion information
    /// - Returns: Text color for the day number
    public static func textColor(for context: DayContext) -> Color {
        // Today: Use completion-aware color for proper contrast
        if context.isToday {
            // High progress (≥80%): White text on colored background
            // Low/no progress (<80%): Dark text on light gray background
            return context.completion >= 0.8 ? .white : .primary
        }

        // Future dates: Subdued appearance
        if context.isFuture {
            return .secondary
        }

        // Past dates: Match background intensity
        return context.completion >= 0.8 ? .white : .primary
    }

    // MARK: - Visual State Logic

    /// Computes the opacity for the day display
    /// - Parameter context: Day context with date information
    /// - Returns: Opacity value (0.0 to 1.0)
    public static func opacity(for context: DayContext) -> Double {
        context.isFuture ? 0.3 : 1.0
    }

    /// Determines whether to show a border around the day circle
    /// - Parameter context: Day context with date information
    /// - Returns: true if border should be shown (today indicator)
    public static func shouldShowBorder(for context: DayContext) -> Bool {
        context.isToday
    }
}
