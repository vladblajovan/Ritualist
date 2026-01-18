import Foundation

// MARK: - Stats Strings

extension Strings {
    // MARK: - Stats/Charts
    public enum Stats {
        public static let howItWorks = String(localized: "stats.howItWorks")
        public static let example = String(localized: "stats.example")
        public static let aboutThisChart = String(localized: "stats.aboutThisChart")
        public static let loadingAnalytics = String(localized: "stats.loadingAnalytics")
        public static let progressTrend = String(localized: "stats.progressTrend")
        public static let aboutProgressTrend = String(localized: "stats.aboutProgressTrend")
        public static let progressTrendChart = String(localized: "stats.progressTrendChart")
        public static let habitPatterns = String(localized: "stats.habitPatterns")
        public static let understandConsistencyTrends = String(localized: "stats.understandConsistencyTrends")
        public static let aboutHabitPatterns = String(localized: "stats.aboutHabitPatterns")
        public static let periodStreaks = String(localized: "stats.periodStreaks")
        public static let performanceDuringPeriod = String(localized: "stats.performanceDuringPeriod")
        public static let perfectDays = String(localized: "stats.perfectDays")
        public static let peak = String(localized: "stats.peak")
        public static let consistency = String(localized: "stats.consistency")
        public static func periodTrend(_ trend: String) -> String { String(format: String(localized: "stats.periodTrend"), trend) }
        public static let categoryPerformance = String(localized: "stats.categoryPerformance")
        public static let tapToViewCategoryHabits = String(localized: "stats.tapToViewCategoryHabits")
        public static func habitsCount(_ count: Int) -> String { String(format: String(localized: "stats.habitsCount"), count) }
        public static let buildingYourProfile = String(localized: "stats.buildingYourProfile")
        public static let completeToUnlockInsights = String(localized: "stats.completeToUnlockInsights")
        public static let excellentEveryDay = String(localized: "stats.excellentEveryDay")
        public static func consistentCompletion(_ percentage: Int) -> String { String(format: String(localized: "stats.consistentCompletion"), percentage) }
        public static let consistentAcrossDays = String(localized: "stats.consistentAcrossDays")
        public static func averageCompletion(_ percentage: Int) -> String { String(format: String(localized: "stats.averageCompletion"), percentage) }
        public static func dayWorksBest(_ day: String) -> String { String(format: String(localized: "stats.dayWorksBest"), day) }
        public static func completionRate(_ percentage: Int) -> String { String(format: String(localized: "stats.completionRate"), percentage) }
        public static let considerRescheduling = String(localized: "stats.considerRescheduling")
        public static let noChangesNeeded = String(localized: "stats.noChangesNeeded")
        public static let weeklyPerformanceChart = String(localized: "stats.weeklyPerformanceChart")
        public static func excellentConsistentPerformance(_ percentage: Int) -> String { String(format: String(localized: "stats.excellentConsistentPerformance"), percentage) }
        public static func consistentPerformance(_ percentage: Int) -> String { String(format: String(localized: "stats.consistentPerformance"), percentage) }
        public static func bestDayPerformance(_ day: String, _ percentage: Int) -> String { String(format: String(localized: "stats.bestDayPerformance"), day, percentage) }
        public static let progressTrendTitle = String(localized: "stats.progressTrendInfo.title")
        public static let progressTrendDescription = String(localized: "stats.progressTrendInfo.description")
        public static let progressTrendDetail1 = String(localized: "stats.progressTrendInfo.detail1")
        public static let progressTrendDetail2 = String(localized: "stats.progressTrendInfo.detail2")
        public static let progressTrendDetail3 = String(localized: "stats.progressTrendInfo.detail3")
        public static let progressTrendExample = String(localized: "stats.progressTrendInfo.example")
        public static let habitPatternsTitle = String(localized: "stats.habitPatternsInfo.title")
        public static let habitPatternsDescription = String(localized: "stats.habitPatternsInfo.description")
        public static let habitPatternsDetail1 = String(localized: "stats.habitPatternsInfo.detail1")
        public static let habitPatternsDetail2 = String(localized: "stats.habitPatternsInfo.detail2")
        public static let habitPatternsDetail3 = String(localized: "stats.habitPatternsInfo.detail3")
        public static let habitPatternsExample = String(localized: "stats.habitPatternsInfo.example")
        public static let periodStreaksTitle = String(localized: "stats.periodStreaksInfo.title")
        public static let periodStreaksDescription = String(localized: "stats.periodStreaksInfo.description")
        public static let periodStreaksDetail1 = String(localized: "stats.periodStreaksInfo.detail1")
        public static let periodStreaksDetail2 = String(localized: "stats.periodStreaksInfo.detail2")
        public static let periodStreaksDetail3 = String(localized: "stats.periodStreaksInfo.detail3")
        public static let periodStreaksExample = String(localized: "stats.periodStreaksInfo.example")
        public static let categoryPerformanceTitle = String(localized: "stats.categoryPerformanceInfo.title")
        public static let categoryPerformanceDescription = String(localized: "stats.categoryPerformanceInfo.description")
        public static let categoryPerformanceDetail1 = String(localized: "stats.categoryPerformanceInfo.detail1")
        public static let categoryPerformanceDetail2 = String(localized: "stats.categoryPerformanceInfo.detail2")
        public static let categoryPerformanceDetail3 = String(localized: "stats.categoryPerformanceInfo.detail3")
        public static let categoryPerformanceExample = String(localized: "stats.categoryPerformanceInfo.example")
        public static let consistencyHeatmap = String(localized: "stats.consistencyHeatmap")
        public static let selectHabit = String(localized: "stats.selectHabit")
        public static let noHabitsForHeatmap = String(localized: "stats.noHabitsForHeatmap")
        public static let heatmapLessLabel = String(localized: "stats.heatmapLessLabel")
        public static let heatmapMoreLabel = String(localized: "stats.heatmapMoreLabel")
        public static let noDataForPeriod = String(localized: "stats.noDataForPeriod")
    }
}
