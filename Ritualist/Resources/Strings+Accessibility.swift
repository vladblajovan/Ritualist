import Foundation

// MARK: - Accessibility Strings

extension Strings {
    // MARK: - Accessibility
    public enum Accessibility {
        public static let previousMonth = String(localized: "accessibilityPreviousMonth")
        public static let nextMonth = String(localized: "accessibilityNextMonth")
        public static let addHabit = String(localized: "accessibilityAddHabit")
        public static let goToToday = String(localized: "accessibilityGoToToday")
        public static func calendarDay(_ day: String) -> String { String(format: String(localized: "accessibilityCalendarDay"), day) }
        public static func habitLogged(_ date: String) -> String { String(format: String(localized: "accessibilityHabitLogged"), date) }
        public static func habitNotLogged(_ date: String) -> String { String(format: String(localized: "accessibilityHabitNotLogged"), date) }
        public static func habitChip(_ habitName: String) -> String { String(format: String(localized: "accessibilityHabitChip"), habitName) }
        public static func monthHeader(_ monthYear: String) -> String { String(format: String(localized: "accessibilityMonthHeader"), monthYear) }
        public static func deleteHabit(_ habitName: String) -> String { String(format: String(localized: "accessibilityDeleteHabit"), habitName) }
        public static func habitStatus(_ habitName: String, _ status: String) -> String { String(format: String(localized: "accessibilityHabitStatus"), habitName, status) }
        public static func streakInfo(_ currentStreak: String, _ bestStreak: String) -> String { String(format: String(localized: "accessibilityStreakInfo"), currentStreak, bestStreak) }
        public static let dashboardEmptyState = String(localized: "accessibilityDashboardEmptyState")
        public static let chartNoData = String(localized: "accessibilityChartNoData")
        public static func chartDescription(avgCompletion: Int, trend: String) -> String { String(format: String(localized: "accessibilityChartDescription"), avgCompletion, trend) }
        public static func categoryLabel(name: String, habitCount: Int, completionPercent: Int) -> String {
            let habitText = habitCount == 1 ? "1 habit" : "\(habitCount) habits"
            return String(format: String(localized: "accessibilityCategoryLabel"), name, habitText, completionPercent)
        }
        public static func progressLabel(completed: Int, total: Int) -> String {
            let percent = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
            return String(format: String(localized: "accessibilityProgressLabel"), completed, total, percent)
        }
        public static func dateLabel(date: String, isToday: Bool) -> String { isToday ? String(format: String(localized: "accessibilityDateLabelToday"), date) : date }
        public static let previousDayHint = String(localized: "accessibilityPreviousDayHint")
        public static let nextDayHint = String(localized: "accessibilityNextDayHint")
        public static let returnToTodayHint = String(localized: "accessibilityReturnToTodayHint")
        public static func habitRowLabel(name: String, isCompleted: Bool, progress: String?) -> String {
            var label = name
            if isCompleted { label += String(localized: "accessibilityHabitCompleted") } else if let progress = progress { label += ", \(progress)" } else { label += String(localized: "accessibilityHabitNotCompleted") }
            return label
        }
        public static let completedSectionHeader = String(localized: "accessibilityCompletedSectionHeader")
        public static let remainingSectionHeader = String(localized: "accessibilityRemainingSectionHeader")
        public static let noHabitsScheduledAccessibility = String(localized: "accessibilityNoHabitsScheduled")
        public static let noHabitsInfoButton = String(localized: "accessibilityNoHabitsInfoButton")
        public static let loadingHabits = String(localized: "accessibilityLoadingHabits")
        public static func habitValidationAnnouncement(_ habitName: String, _ message: String) -> String { String(format: String(localized: "accessibilityHabitValidationAnnouncement"), habitName, message) }
        public static func syncedDataSummary(habits: Int, categories: Int) -> String { String(format: String(localized: "accessibilitySyncedDataSummary"), habits, categories) }
    }

    // MARK: - Number Formatting
    public enum Format {
        public static func habitValueWithUnit(_ value: String, _ unit: String) -> String { String(format: String(localized: "format.habit_value_with_unit"), value, unit) }
        public static func progressPercentage(_ percentage: String) -> String { String(format: String(localized: "format.progress_percentage"), percentage) }
    }
}
