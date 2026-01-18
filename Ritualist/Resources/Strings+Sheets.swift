import Foundation

// MARK: - Sheet Strings

extension Strings {
    // MARK: - Numeric Habit Log
    public enum NumericHabitLog {
        public static let title = String(localized: "numericHabitLog.title")
        public static let reset = String(localized: "numericHabitLog.reset")
        public static let completeAll = String(localized: "numericHabitLog.completeAll")
        public static let wellDoneExtraMile = String(localized: "numericHabitLog.wellDoneExtraMile")
        public static let loadingCurrentValue = String(localized: "numericHabitLog.loadingCurrentValue")
        public static let extraMileOnFire = String(localized: "numericHabitLog.extraMile.onFire")
        public static let extraMileCrushing = String(localized: "numericHabitLog.extraMile.crushing")
        public static let extraMileAboveBeyond = String(localized: "numericHabitLog.extraMile.aboveBeyond")
        public static let extraMileOverachiever = String(localized: "numericHabitLog.extraMile.overachiever")
        public static let extraMileExtraEffort = String(localized: "numericHabitLog.extraMile.extraEffort")
        public static let extraMileBeyondExpectations = String(localized: "numericHabitLog.extraMile.beyondExpectations")
        public static var extraMilePhrases: [String] { [extraMileOnFire, extraMileCrushing, extraMileAboveBeyond, extraMileOverachiever, extraMileExtraEffort, extraMileBeyondExpectations] }
        public static let decreaseHint = String(localized: "numericHabitLog.accessibility.decreaseHint")
        public static let increaseHint = String(localized: "numericHabitLog.accessibility.increaseHint")
        public static let resetHint = String(localized: "numericHabitLog.accessibility.resetHint")
        public static let completeAllHint = String(localized: "numericHabitLog.accessibility.completeAllHint")
        public static let doneHint = String(localized: "numericHabitLog.accessibility.doneHint")
        public static func quickIncrementLabel(_ amount: String) -> String { String(format: String(localized: "numericHabitLog.accessibility.quickIncrementLabel"), amount) }
        public static func quickIncrementHint(_ amount: String) -> String { String(format: String(localized: "numericHabitLog.accessibility.quickIncrementHint"), amount) }
        public static func progressLabel(current: Int, target: Int, isCompleted: Bool) -> String {
            if isCompleted { return String(format: String(localized: "numericHabitLog.accessibility.progressCompleted"), current, target) }
            return String(format: String(localized: "numericHabitLog.accessibility.progressInProgress"), current, target)
        }
    }

    // MARK: - Uncomplete Habit Sheet
    public enum UncompleteHabitSheet {
        public static let completed = String(localized: "uncompleteHabitSheet.completed")
        public static let markAsNotCompleted = String(localized: "uncompleteHabitSheet.markAsNotCompleted")
        public static let markAsNotCompletedHint = String(localized: "uncompleteHabitSheet.accessibility.markAsNotCompletedHint")
        public static let cancelHint = String(localized: "uncompleteHabitSheet.accessibility.cancelHint")
        public static func headerAccessibilityLabel(_ habitName: String) -> String { String(format: String(localized: "uncompleteHabitSheet.accessibility.headerLabel"), habitName) }
        public static func screenChangedAnnouncement(_ habitName: String) -> String { String(format: String(localized: "uncompleteHabitSheet.accessibility.screenChanged"), habitName) }
    }

    // MARK: - Complete Habit Sheet
    public enum CompleteHabitSheet {
        public static let notCompleted = String(localized: "completeHabitSheet.notCompleted")
        public static let markAsCompleted = String(localized: "completeHabitSheet.markAsCompleted")
        public static let markAsCompletedHint = String(localized: "completeHabitSheet.accessibility.markAsCompletedHint")
        public static let cancelHint = String(localized: "completeHabitSheet.accessibility.cancelHint")
        public static func headerAccessibilityLabel(_ habitName: String) -> String { String(format: String(localized: "completeHabitSheet.accessibility.headerLabel"), habitName) }
        public static func screenChangedAnnouncement(_ habitName: String) -> String { String(format: String(localized: "completeHabitSheet.accessibility.screenChanged"), habitName) }
    }

    // MARK: - User Guide
    public enum UserGuide {
        public static let title = String(localized: "userGuide.title")
        public static let tableOfContents = String(localized: "userGuide.tableOfContents")
        public static let searchPlaceholder = String(localized: "userGuide.searchPlaceholder")
    }
}
