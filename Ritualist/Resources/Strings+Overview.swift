import Foundation

// MARK: - Overview & Dashboard Strings

extension Strings {
    // MARK: - Overview/Calendar
    public enum Overview {
        public static let instructions = String(localized: "overviewInstructions")
        public static let yourHabits = String(localized: "overviewYourHabits")
        public static let calendar = String(localized: "overviewCalendar")
        public static let stats = String(localized: "overviewStats")
        public static let current = String(localized: "overviewCurrent")
        public static let best = String(localized: "overviewBest")
        public static func dayPlural(_ count: Int) -> String { String.localizedStringWithFormat(NSLocalizedString("overviewDayPlural", comment: "Streak count with proper pluralization"), count) }
        public static let daySingular = String(localized: "overviewDaySingular")
        public static let dayPlural = String(localized: "overviewDayPluralStatic")
        public static let tooManyActiveHabits = String(localized: "overview.tooManyActiveHabits")
        public static func deactivateHabitsOrUpgrade(_ count: Int) -> String { String(format: String(localized: "overview.deactivateHabitsOrUpgrade"), count) }
        public static let manageHabits = String(localized: "overview.manageHabits")
        public static let upgrade = String(localized: "overview.upgrade")
        public static let daysActive = String(localized: "overview.daysActive")
        public static let achievement = String(localized: "overview.achievement")
        public static let howStreaksWork = String(localized: "overview.howStreaksWork")
        public static let daysActiveExplanation = String(localized: "overview.daysActiveExplanation")
        public static let achievementLevelsExplanation = String(localized: "overview.achievementLevelsExplanation")
        public static let streakBuilding = String(localized: "overview.streakBuilding")
        public static let streakStrong = String(localized: "overview.streakStrong")
        public static let streakFireChampion = String(localized: "overview.streakFireChampion")
        public static let streakDetails = String(localized: "overview.streakDetails")
        public static let personalityInsights = String(localized: "overview.personalityInsights")
        public static func basedOnProfile(_ trait: String) -> String { String(format: String(localized: "overview.basedOnProfile"), trait) }
        public static let dataReadyForAnalysis = String(localized: "overview.dataReadyForAnalysis")
        public static let unlockWithPro = String(localized: "overview.unlockWithPro")
        public static let insightsFromPreviousAnalysis = String(localized: "overview.insightsFromPreviousAnalysis")
        public static let completeRequirements = String(localized: "overview.completeRequirements")
        public static let reminderIcons = String(localized: "overview.reminderIcons")
        public static let reminderIconsDescription = String(localized: "overview.reminderIconsDescription")
        public static let scheduleIcons = String(localized: "overview.scheduleIcons")
        public static let scheduleIconsDescription = String(localized: "overview.scheduleIconsDescription")
        public static let streakIndicator = String(localized: "overview.streakIndicator")
        public static let streakIndicatorDescription = String(localized: "overview.streakIndicatorDescription")
        public static let habitStatus = String(localized: "overview.habitStatus")
        public static let streakAtRisk = String(localized: "overview.streakAtRisk")
        public static let streakAtRiskDescription = String(localized: "overview.streakAtRiskDescription")
        public static let removeLogEntry = String(localized: "overview.removeLogEntry")
        public static let remove = String(localized: "overview.remove")
        public static func removeLogMessage(_ habitName: String) -> String { String(format: String(localized: "overview.removeLogMessage"), habitName) }
        public static func todayDate(_ dateString: String) -> String { String(format: String(localized: "overview.todayDate"), dateString) }
        public static func nextHabit(_ habitName: String) -> String { String(format: String(localized: "overview.nextHabit"), habitName) }
        public static let remaining = String(localized: "overview.remaining")
        public static let completed = String(localized: "overview.completed")
        public static let analysisInProgress = String(localized: "overview.analysisInProgress")
        public static let weeklyInsights = String(localized: "overview.weeklyInsights")
        public static let gatheringInsights = String(localized: "overview.gatheringInsights")
        public static let completeHabitsToUnlock = String(localized: "overview.completeHabitsToUnlock")
        public static let currentStreaks = String(localized: "overview.currentStreaks")
        public static let streaks = String(localized: "overview.streaks")
        public static func streaksCount(_ count: Int) -> String { String(format: String(localized: "overview.streaksCount"), count, count == 1 ? "streak" : "streaks") }
        public static let loadingStreaks = String(localized: "overview.loadingStreaks")
        public static let noActiveStreaks = String(localized: "overview.noActiveStreaks")
        public static let startCompletingHabits = String(localized: "overview.startCompletingHabits")
        public static let noHabitsInfoTitle = String(localized: "overview.noHabitsInfo.title")
        public static let noHabitsReasonHeader = String(localized: "overview.noHabitsInfo.reasonHeader")
        public static let noHabitsReasonScheduleTitle = String(localized: "overview.noHabitsInfo.schedule.title")
        public static let noHabitsReasonScheduleDesc = String(localized: "overview.noHabitsInfo.schedule.desc")
        public static let noHabitsReasonStartDateTitle = String(localized: "overview.noHabitsInfo.startDate.title")
        public static let noHabitsReasonStartDateDesc = String(localized: "overview.noHabitsInfo.startDate.desc")
        public static let noHabitsReasonFooter = String(localized: "overview.noHabitsInfo.footer")
    }

    // MARK: - Dashboard
    public enum Dashboard {
        public static let title = String(localized: "dashboardTitle")
        public static let totalHabits = String(localized: "dashboardTotalHabits")
        public static let completedHabits = String(localized: "dashboardCompletedHabits")
        public static let overallCompletion = String(localized: "dashboardOverallCompletion")
        public static let weeklyProgress = String(localized: "dashboardWeeklyProgress")
        public static let monthlyProgress = String(localized: "dashboardMonthlyProgress")
        public static let consistencyScore = String(localized: "dashboardConsistencyScore")
        public static let topPerformers = String(localized: "dashboardTopPerformers")
        public static let needsImprovement = String(localized: "dashboardNeedsImprovement")
        public static let noDataAvailable = String(localized: "dashboardNoDataAvailable")
        public static let startTrackingMessage = String(localized: "dashboardStartTrackingMessage")
        public static let timePeriodPicker = String(localized: "dashboardTimePeriodPicker")
        public static let thisWeek = String(localized: "dashboardThisWeek")
        public static let thisMonth = String(localized: "dashboardThisMonth")
        public static let last6Months = String(localized: "dashboardLast6Months")
        public static let lastYear = String(localized: "dashboardLastYear")
        public static let allTime = String(localized: "dashboardAllTime")
        public static let optimizationConsistentPerformance = String(localized: "dashboardOptimizationConsistentPerformance")
        public static let optimizationNearPerfect = String(localized: "dashboardOptimizationNearPerfect")
        public static let optimizationKeepBuilding = String(localized: "dashboardOptimizationKeepBuilding")
        public static let optimizationSuggestion = String(localized: "dashboardOptimizationSuggestion")
    }
}
