import SwiftUI
import Foundation
import FactoryKit

// swiftlint:disable file_length type_body_length

// MARK: - Data Models

public struct TodaysSummary {
    public let completedHabitsCount: Int
    public let completedHabits: [Habit]
    public let totalHabits: Int
    public let completionPercentage: Double
    public let motivationalMessage: String
    public let incompleteHabits: [Habit]
    
    public init(completedHabitsCount: Int, completedHabits: [Habit], totalHabits: Int, incompleteHabits: [Habit]) {
        self.completedHabitsCount = completedHabitsCount
        self.completedHabits = completedHabits
        self.totalHabits = totalHabits
        self.completionPercentage = totalHabits > 0 ? Double(completedHabitsCount) / Double(totalHabits) : 0.0
        self.incompleteHabits = incompleteHabits
        
        // Generate motivational message based on progress
        if completionPercentage >= 1.0 {
            self.motivationalMessage = "Perfect day! All habits completed! 🎉"
        } else if completionPercentage >= 0.8 {
            let remaining = totalHabits - completedHabitsCount
            self.motivationalMessage = "Great work! \(remaining) habit\(remaining == 1 ? "" : "s") left"
        } else if completionPercentage >= 0.5 {
            self.motivationalMessage = "Keep going! You're halfway there"
        } else if completedHabitsCount > 0 {
            self.motivationalMessage = "Good start! Let's build momentum"
        } else {
            self.motivationalMessage = "Ready to start your day?"
        }
    }
}

public struct WeeklyProgress {
    public let daysCompleted: [Bool] // 7 days, starting from user's week start day
    public let weeklyCompletionRate: Double
    public let currentDayIndex: Int
    public let weekDescription: String
    
    public init(daysCompleted: [Bool], currentDayIndex: Int) {
        self.daysCompleted = daysCompleted
        self.currentDayIndex = currentDayIndex
        
        let completedDays = daysCompleted.filter { $0 }.count
        self.weeklyCompletionRate = Double(completedDays) / 7.0
        
        let percentage = Int(weeklyCompletionRate * 100)
        self.weekDescription = "\(completedDays) days completed • \(percentage)% weekly"
    }
}

public struct StreakInfo: Identifiable {
    public let id: String
    public let habitName: String
    public let emoji: String
    public let currentStreak: Int
    public let isActive: Bool
    
    public var flameCount: Int {
        if currentStreak >= 30 { return 3 }
        else if currentStreak >= 14 { return 2 }
        else if currentStreak >= 7 { return 1 }
        else { return 0 }
    }
    
    public var flameEmoji: String {
        String(repeating: "🔥", count: flameCount)
    }
    
    public init(id: String, habitName: String, emoji: String, currentStreak: Int, isActive: Bool) {
        self.id = id
        self.habitName = habitName
        self.emoji = emoji
        self.currentStreak = currentStreak
        self.isActive = isActive
    }
}

public struct SmartInsight {
    public let title: String
    public let message: String
    public let type: InsightType
    
    public enum InsightType {
        case pattern
        case suggestion
        case celebration
        case warning
    }
    
    public init(title: String, message: String, type: InsightType) {
        self.title = title
        self.message = message
        self.type = type
    }
}

// MARK: - ViewModel

@MainActor
public final class OverviewV2ViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var todaysSummary: TodaysSummary?
    @Published public var weeklyProgress: WeeklyProgress?
    @Published public var activeStreaks: [StreakInfo] = []
    @Published public var smartInsights: [SmartInsight] = []
    @Published public var personalityInsights: [OverviewPersonalityInsight] = []
    @Published public var shouldShowPersonalityInsights = false
    @Published public var dominantPersonalityTrait: String? = nil
    @Published public var selectedDate: Date = Date()
    @Published public var isCalendarExpanded: Bool = false
    @Published public var viewingDate: Date = Date() // The date being viewed in Today's Progress card
    @Published public var showInspirationCard: Bool = false
    
    // Inspiration card tracking
    private var lastShownInspirationTrigger: InspirationTrigger?
    private var sessionStartTime: Date = Date()
    private var dismissedTriggersToday: Set<InspirationTrigger> = []
    
    @Published public var isLoading: Bool = false
    @Published public var error: Error?
    
    // MARK: - Computed Properties
    public var incompleteHabits: [Habit] {
        todaysSummary?.incompleteHabits ?? []
    }
    
    public var completedHabits: [Habit] {
        todaysSummary?.completedHabits ?? []
    }
    
    public var shouldShowQuickActions: Bool {
        // Show QuickActions when there are incomplete habits OR completed habits to display
        guard isViewingToday else { return false }
        return !incompleteHabits.isEmpty || !completedHabits.isEmpty
    }
    
    public var shouldShowActiveStreaks: Bool {
        !activeStreaks.isEmpty && activeStreaks.contains { $0.currentStreak >= 3 }
    }
    
    public var shouldShowInsights: Bool {
        !smartInsights.isEmpty
    }
    
    public var canGoToPreviousDay: Bool {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return viewingDate > calendar.startOfDay(for: thirtyDaysAgo)
    }
    
    public var canGoToNextDay: Bool {
        let calendar = Calendar.current
        return viewingDate < calendar.startOfDay(for: Date())
    }
    
    public var isViewingToday: Bool {
        let calendar = Calendar.current
        return calendar.isDate(viewingDate, inSameDayAs: Date())
    }
    
    public var currentSlogan: String {
        slogansService.getCurrentSlogan()
    }
    
    public var currentTimeOfDay: TimeOfDay {
        slogansService.getCurrentTimeOfDay()
    }
    
    public var shouldShowInspirationCard: Bool {
        guard isViewingToday else { return false }
        return showInspirationCard
    }
    
    private enum InspirationTrigger: CaseIterable, Hashable {
        case sessionStart          // First app open of the day
        case morningMotivation     // 0% completion in morning
        case firstHabitComplete    // Just completed first habit
        case halfwayPoint         // Hit 50% completion
        case strugglingMidDay     // <40% completion at noon
        case afternoonPush        // <60% completion in afternoon (3-5pm)
        case strongFinish         // Hit 75%+ completion
        case perfectDay           // 100% completion
        case eveningReflection    // Evening with good progress (>60%)
        case weekendMotivation    // Weekend-specific encouragement
        case comebackStory        // Improved from yesterday
        
        var cooldownMinutes: Int {
            switch self {
            case .sessionStart, .perfectDay:
                return 0  // No cooldown
            case .firstHabitComplete, .halfwayPoint, .strongFinish:
                return 60 // 1 hour cooldown
            case .morningMotivation, .strugglingMidDay, .afternoonPush:
                return 120 // 2 hour cooldown
            case .eveningReflection, .weekendMotivation, .comebackStory:
                return 180 // 3 hour cooldown
            }
        }
    }
    
    public var weeklyCompletionData: [Date: Double] {
        // Return subset of monthly data for current week
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var weeklyData: [Date: Double] = [:]
        
        // Get completion data for each day of the current week from monthly data
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let startOfDay = calendar.startOfDay(for: date)
                weeklyData[startOfDay] = monthlyCompletionData[startOfDay] ?? 0.0
            }
        }
        
        return weeklyData
    }
    
    @Published public var monthlyCompletionData: [Date: Double] = [:]
    
    // MARK: - Dependencies
    @Injected(\.habitRepository) private var habitRepository
    @Injected(\.logRepository) private var logRepository
    @Injected(\.slogansService) private var slogansService
    @Injected(\.userService) private var userService
    @Injected(\.calculateCurrentStreak) private var calculateCurrentStreakUseCase
    @Injected(\.getPersonalityProfileUseCase) private var getPersonalityProfileUseCase
    @Injected(\.getPersonalityInsightsUseCase) private var getPersonalityInsightsUseCase
    @Injected(\.updatePersonalityAnalysisUseCase) private var updatePersonalityAnalysisUseCase
    @Injected(\.personalityAnalysisRepository) private var personalityAnalysisRepository
    @Injected(\.personalityDeepLinkCoordinator) private var personalityDeepLinkCoordinator
    
    private var userId: UUID { 
        userService.currentProfile.id 
    }
    
    public init() {
        // Initialize dismissed triggers for the current day
        resetDismissedTriggersIfNewDay()
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            async let todaySummaryTask = loadTodaysSummary()
            async let weeklyProgressTask = loadWeeklyProgress()
            async let activeStreaksTask = loadActiveStreaks()
            async let insightsTask = loadSmartInsights()
            async let monthlyDataTask = loadMonthlyCompletionData()
            
            let (todaySummary, weeklyProgress, streaks, insights, monthlyData) = try await (
                todaySummaryTask,
                weeklyProgressTask,
                activeStreaksTask,
                insightsTask,
                monthlyDataTask
            )
            
            // Load personality insights separately (non-blocking)
            Task {
                await loadPersonalityInsights()
            }
            
            await MainActor.run {
                self.todaysSummary = todaySummary
                self.weeklyProgress = weeklyProgress
                self.activeStreaks = streaks
                self.smartInsights = insights
                self.monthlyCompletionData = monthlyData
                
                // Check if we should show inspiration card contextually
                self.checkAndShowInspirationCard()
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                print("Failed to load OverviewV2 data: \(error)")
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    public func refresh() async {
        await loadData()
    }
    
    public func openPersonalityAnalysis() {
        Task { @MainActor in
            personalityDeepLinkCoordinator.showPersonalityAnalysisDirectly()
        }
    }
    
    public func refreshPersonalityInsights() async {
        await loadPersonalityInsights()
    }
    
    public func completeHabit(_ habit: Habit) async {
        do {
            // Create habit log for the viewing date (could be today or retroactive)
            let log = HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: viewingDate,
                value: habit.kind == .numeric ? habit.dailyTarget ?? 1.0 : 1.0
            )
            
            try await logRepository.upsert(log)
            
            // Refresh data to show updated progress
            await loadData()
            
        } catch {
            await MainActor.run {
                self.error = error
                print("Failed to complete habit: \(error)")
            }
        }
    }
    
    public func goToPreviousDay() {
        let calendar = Calendar.current
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: viewingDate),
           canGoToPreviousDay {
            viewingDate = previousDay
            Task {
                await loadData()
            }
        }
    }
    
    public func goToNextDay() {
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: viewingDate),
           canGoToNextDay {
            viewingDate = nextDay
            Task {
                await loadData()
            }
        }
    }
    
    public func goToToday() {
        viewingDate = Date()
        Task {
            await loadData()
        }
    }
    
    public func showInspiration() {
        showInspirationCard = true
    }
    
    public func triggerMotivation() {
        // Manual motivation trigger - can be called from UI buttons or gestures
        let trigger: InspirationTrigger = {
            guard let summary = todaysSummary else { return .morningMotivation }
            
            let completionRate = summary.completionPercentage
            let timeOfDay = currentTimeOfDay
            
            if completionRate >= 1.0 {
                return .perfectDay
            } else if completionRate >= 0.75 {
                return .strongFinish
            } else if completionRate >= 0.5 {
                return .halfwayPoint
            } else {
                switch timeOfDay {
                case .morning: return .morningMotivation
                case .noon: return .strugglingMidDay
                case .evening: return .eveningReflection
                }
            }
        }()
        
        showInspirationWithTrigger(trigger)
    }
    
    private func checkForComebackStory(currentCompletion: Double) async -> Bool {
        // Check if today's progress is significantly better than yesterday
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return false }
        
        do {
            let yesterdayHabits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
            var yesterdayCompletedCount = 0
            
            for habit in yesterdayHabits {
                let logs = try await logRepository.logs(for: habit.id)
                if logs.contains(where: { calendar.isDate($0.date, inSameDayAs: yesterday) }) {
                    yesterdayCompletedCount += 1
                }
            }
            
            let yesterdayCompletion = yesterdayHabits.isEmpty ? 0.0 : Double(yesterdayCompletedCount) / Double(yesterdayHabits.count)
            
            // If today is 25%+ better than yesterday, it's a comeback story
            return currentCompletion > yesterdayCompletion + 0.25 && yesterdayCompletion < 0.6
        } catch {
            // Ignore errors for comeback detection
            return false
        }
    }
    
    public func hideInspiration() {
        // Mark current trigger as dismissed for today
        if let currentTrigger = lastShownInspirationTrigger {
            dismissedTriggersToday.insert(currentTrigger)
            saveDismissedTriggers()
        }
        showInspirationCard = false
    }
    
    private func checkAndShowInspirationCard() {
        guard isViewingToday, let summary = todaysSummary else { return }
        
        Task {
            let triggers = await evaluateInspirationTriggers(summary: summary)
            
            await MainActor.run {
                if let bestTrigger = selectBestTrigger(from: triggers) {
                    showInspirationWithTrigger(bestTrigger)
                }
            }
        }
    }
    
    private func evaluateInspirationTriggers(summary: TodaysSummary) async -> [InspirationTrigger] {
        var triggers: [InspirationTrigger] = []
        let timeOfDay = currentTimeOfDay
        let completionRate = summary.completionPercentage
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let isWeekend = [1, 7].contains(calendar.component(.weekday, from: now))
        
        // Session Start (first load of the day)
        if calendar.isDate(sessionStartTime, inSameDayAs: now) && 
           calendar.dateComponents([.minute], from: sessionStartTime, to: now).minute! < 5 {
            triggers.append(.sessionStart)
        }
        
        // Time-based triggers
        switch timeOfDay {
        case .morning:
            if completionRate == 0.0 {
                triggers.append(.morningMotivation)
            }
            if isWeekend {
                triggers.append(.weekendMotivation)
            }
        case .noon:
            if completionRate < 0.4 {
                triggers.append(.strugglingMidDay)
            }
        case .evening:
            if completionRate >= 0.6 {
                triggers.append(.eveningReflection)
            }
        }
        
        // Afternoon push (3-5 PM)
        if hour >= 15 && hour < 17 && completionRate < 0.6 {
            triggers.append(.afternoonPush)
        }
        
        // Progress-based triggers
        if completionRate >= 1.0 {
            triggers.append(.perfectDay)
        } else if completionRate >= 0.75 {
            triggers.append(.strongFinish)
        } else if completionRate >= 0.5 {
            triggers.append(.halfwayPoint)
        } else if completionRate > 0.0 && summary.completedHabitsCount == 1 {
            triggers.append(.firstHabitComplete)
        }
        
        // Comeback story trigger (improved from yesterday)
        if await checkForComebackStory(currentCompletion: completionRate) {
            triggers.append(.comebackStory)
        }
        
        return triggers
    }
    
    private func selectBestTrigger(from triggers: [InspirationTrigger]) -> InspirationTrigger? {
        let now = Date()
        
        // Filter out triggers that are on cooldown or dismissed today
        let availableTriggers = triggers.filter { trigger in
            // Skip if already dismissed today
            if dismissedTriggersToday.contains(trigger) {
                return false
            }
            
            // Check cooldown
            if let lastTrigger = lastShownInspirationTrigger,
               lastTrigger == trigger,
               let lastShownTime = Calendar.current.dateInterval(of: .day, for: now)?.start {
                let cooldownEnd = Calendar.current.date(byAdding: .minute, value: trigger.cooldownMinutes, to: lastShownTime) ?? lastShownTime
                return now >= cooldownEnd
            }
            return true
        }
        
        // Priority order (most impactful first)
        let priorityOrder: [InspirationTrigger] = [
            .perfectDay,           // Celebrate success immediately
            .sessionStart,         // Welcome back
            .firstHabitComplete,   // Build momentum
            .strongFinish,         // Celebrate near-completion
            .halfwayPoint,         // Acknowledge progress
            .strugglingMidDay,     // Provide mid-day boost
            .afternoonPush,        // Late-day motivation
            .eveningReflection,    // End positively
            .morningMotivation,    // Start the day right
            .weekendMotivation,    // Weekend encouragement
            .comebackStory         // Recovery motivation
        ]
        
        // Return highest priority available trigger
        return priorityOrder.first { availableTriggers.contains($0) }
    }
    
    private func showInspirationWithTrigger(_ trigger: InspirationTrigger) {
        let delay: Int = {
            switch trigger {
            case .perfectDay:
                return 1200  // Celebrate immediately but with dramatic pause
            case .firstHabitComplete, .halfwayPoint, .strongFinish:
                return 800   // Quick positive reinforcement
            case .sessionStart:
                return 2000  // Let user settle in first
            default:
                return 1500  // Standard timing
            }
        }()
        
        Task {
            try? await Task.sleep(for: .milliseconds(delay))
            await MainActor.run {
                self.lastShownInspirationTrigger = trigger
                self.showInspirationCard = true
            }
        }
    }
    
    public var currentInspirationMessage: String {
        guard let trigger = lastShownInspirationTrigger else {
            return slogansService.getCurrentSlogan()
        }
        return getPersonalizedMessage(for: trigger)
    }
    
    // MARK: - Private Methods
    
    private func loadTodaysSummary() async throws -> TodaysSummary {
        let targetDate = viewingDate
        let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
        
        var allTargetDateLogs: [HabitLog] = []
        for habit in habits {
            let habitLogs = try await logRepository.logs(for: habit.id)
            let targetDateLogs = habitLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
            allTargetDateLogs.append(contentsOf: targetDateLogs)
        }
        
        let completedHabitsCount = allTargetDateLogs.count
        
        // Create completed habits array (sorted by completion time)
        let completedHabits = habits.filter { habit in
            allTargetDateLogs.contains { $0.habitID == habit.id }
        }.sorted { habit1, habit2 in
            // Sort by latest log time for each habit (most recent at end)
            let habit1Logs = allTargetDateLogs.filter { $0.habitID == habit1.id }
            let habit2Logs = allTargetDateLogs.filter { $0.habitID == habit2.id }
            let habit1LatestTime = habit1Logs.map { $0.date }.max() ?? Date.distantPast
            let habit2LatestTime = habit2Logs.map { $0.date }.max() ?? Date.distantPast
            return habit1LatestTime < habit2LatestTime
        }
        
        let incompleteHabits = habits.filter { habit in
            // Only show as incomplete if not completed AND not a future date
            let hasLog = allTargetDateLogs.contains { $0.habitID == habit.id }
            return !hasLog && targetDate <= Date()
        }
        
        return TodaysSummary(
            completedHabitsCount: completedHabitsCount,
            completedHabits: completedHabits,
            totalHabits: habits.count,
            incompleteHabits: incompleteHabits
        )
    }
    
    private func loadWeeklyProgress() async throws -> WeeklyProgress {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            throw NSError(domain: "WeeklyProgress", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get week interval"])
        }
        
        var daysCompleted: [Bool] = []
        // Calculate current day index relative to week start day
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sunday, 2=Monday, etc.
        let firstWeekday = calendar.firstWeekday // 1=Sunday, 2=Monday, etc.
        let currentDayIndex = (todayWeekday - firstWeekday + 7) % 7
        
        // Check each day of the week
        for dayOffset in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) {
                let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
                
                var dayLogs: [HabitLog] = []
                for habit in habits {
                    let habitLogs = try await logRepository.logs(for: habit.id)
                    let logsForDay = habitLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: dayDate) }
                    dayLogs.append(contentsOf: logsForDay)
                }
                
                // Consider day completed if any habits were logged
                let isCompleted = !dayLogs.isEmpty && Double(dayLogs.count) / Double(habits.count) > 0.5
                daysCompleted.append(isCompleted)
            } else {
                daysCompleted.append(false)
            }
        }
        
        return WeeklyProgress(daysCompleted: daysCompleted, currentDayIndex: currentDayIndex)
    }
    
    private func loadActiveStreaks() async throws -> [StreakInfo] {
        let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
        var streaks: [StreakInfo] = []
        
        for habit in habits {
            // Calculate current streak (simplified)
            let currentStreak = try await calculateCurrentStreak(for: habit)
            
            if currentStreak >= 3 { // Only show streaks of 3+ days
                let streakInfo = StreakInfo(
                    id: habit.id.uuidString,
                    habitName: habit.name,
                    emoji: habit.emoji ?? "📊",
                    currentStreak: currentStreak,
                    isActive: true
                )
                streaks.append(streakInfo)
            }
        }
        
        // Sort by streak length (longest first)
        return streaks.sorted { $0.currentStreak > $1.currentStreak }
    }
    
    private func calculateCurrentStreak(for habit: Habit) async throws -> Int {
        // Get all logs for this habit
        let logs = try await logRepository.logs(for: habit.id)
        
        // Use the real streak calculation use case
        let today = Date()
        return calculateCurrentStreakUseCase.execute(habit: habit, logs: logs, asOf: today)
    }
    
    private func loadSmartInsights() async throws -> [SmartInsight] {
        // Smart Insights now only contains basic habit pattern analysis
        return try await generateBasicHabitInsights()
    }
    
    private func loadPersonalityInsights() async {
        do {
            // Check if personality analysis is enabled and sufficient data exists
            let isEligible = try await checkPersonalityAnalysisEligibility()
            
            await MainActor.run {
                shouldShowPersonalityInsights = isEligible
            }
            
            guard isEligible else {
                await MainActor.run {
                    personalityInsights = []
                }
                return
            }
            
            // Try to get existing personality profile
            var personalityProfile = try await getPersonalityProfileUseCase.execute(for: userId)
            
            // If no profile exists but user is eligible, auto-generate one
            if personalityProfile == nil {
                do {
                    let newProfile = try await updatePersonalityAnalysisUseCase.execute(for: userId)
                    personalityProfile = newProfile
                } catch {
                    await MainActor.run {
                        shouldShowPersonalityInsights = false
                        personalityInsights = []
                    }
                    return
                }
            }
            
            guard let profile = personalityProfile else {
                await MainActor.run {
                    shouldShowPersonalityInsights = false
                    personalityInsights = []
                }
                return
            }
            
            // Get personality-based insights
            let insights = getPersonalityInsightsUseCase.getAllInsights(for: profile)
            
            // Convert to OverviewPersonalityInsight format for the new card
            var cardInsights: [OverviewPersonalityInsight] = []
            
            // Add pattern insights
            for insight in insights.patternInsights.prefix(2) {
                cardInsights.append(OverviewPersonalityInsight(
                    title: insight.title,
                    message: insight.description,
                    type: .pattern
                ))
            }
            
            // Add habit recommendations
            for insight in insights.habitRecommendations.prefix(2) {
                cardInsights.append(OverviewPersonalityInsight(
                    title: insight.title,
                    message: insight.actionable,
                    type: .recommendation
                ))
            }
            
            // Add one motivational insight
            if let motivationalInsight = insights.motivationalInsights.first {
                cardInsights.append(OverviewPersonalityInsight(
                    title: motivationalInsight.title,
                    message: motivationalInsight.actionable,
                    type: .motivation
                ))
            }
            
            await MainActor.run {
                personalityInsights = cardInsights
                dominantPersonalityTrait = profile.dominantTrait.displayName
            }
            
        } catch {
            await MainActor.run {
                shouldShowPersonalityInsights = false
                personalityInsights = []
            }
        }
    }
    
    private func checkPersonalityAnalysisEligibility() async throws -> Bool {
        // Use the proper repository validation instead of simplified checks
        do {
            // Check if personality analysis service is enabled for this user
            let isEnabled = try await personalityAnalysisRepository.isPersonalityAnalysisEnabled(for: userId)
            
            guard isEnabled else {
                return false
            }
            
            // Use the proper eligibility validation from the repository
            let eligibility = try await personalityAnalysisRepository.validateAnalysisEligibility(for: userId)
            return eligibility.isEligible
            
        } catch {
            return false
        }
    }
    
    private func generateBasicHabitInsights() async throws -> [SmartInsight] {
        var insights: [SmartInsight] = []
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        // Get user's active habits and recent logs
        let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
        guard !habits.isEmpty else {
            return []
        }
        
        // Analyze completion patterns over the past week
        var totalCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)
        
        for habit in habits {
            let logs = try await logRepository.logs(for: habit.id)
            let recentLogs = logs.filter { log in
                log.date >= sevenDaysAgo && log.date <= today
            }
            
            totalCompletions += recentLogs.count
            
            // Count completions per day
            for log in recentLogs {
                let daysSinceStart = calendar.dateComponents([.day], from: sevenDaysAgo, to: log.date).day ?? 0
                if daysSinceStart >= 0 && daysSinceStart < 7 {
                    dailyCompletions[daysSinceStart] += 1
                }
            }
        }
        
        let totalPossibleCompletions = habits.count * 7
        let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0
        
        // Generate insights based on actual patterns
        if completionRate >= 0.8 {
            insights.append(SmartInsight(
                title: "Excellent Consistency",
                message: "You're completing \(Int(completionRate * 100))% of your habits this week!",
                type: .celebration
            ))
        } else if completionRate >= 0.6 {
            insights.append(SmartInsight(
                title: "Good Progress",
                message: "You're on track with \(Int(completionRate * 100))% completion. Keep building momentum!",
                type: .pattern
            ))
        } else if completionRate >= 0.3 {
            insights.append(SmartInsight(
                title: "Room for Growth",
                message: "Focus on consistency - even small daily wins add up to big results.",
                type: .suggestion
            ))
        } else {
            insights.append(SmartInsight(
                title: "Fresh Start",
                message: "Every day is a new opportunity. Start with just one habit today.",
                type: .suggestion
            ))
        }
        
        // Find best performing day
        if let bestDayIndex = dailyCompletions.enumerated().max(by: { $0.element < $1.element })?.offset {
            let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            let startDayIndex = calendar.component(.weekday, from: sevenDaysAgo) - 1
            let bestDayName = dayNames[(startDayIndex + bestDayIndex) % 7]
            
            if dailyCompletions[bestDayIndex] > 0 {
                insights.append(SmartInsight(
                    title: "\(bestDayName) Strength",
                    message: "You completed \(dailyCompletions[bestDayIndex]) habits on \(bestDayName) - your strongest day!",
                    type: .pattern
                ))
            }
        }
        
        // Add motivational insight if they have multiple habits
        if habits.count >= 3 {
            insights.append(SmartInsight(
                title: "Multi-Habit Builder",
                message: "Tracking \(habits.count) habits shows commitment to growth. Focus on consistency over perfection.",
                type: .suggestion
            ))
        }
        
        return insights
    }
    
    
    private func loadMonthlyCompletionData() async throws -> [Date: Double] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get all active habits
        let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
        guard !habits.isEmpty else { return [:] }
        
        var completionData: [Date: Double] = [:]
        
        // Load data for the past 30 days
        for i in 0...30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                
                // Get all logs for this date
                var completedCount = 0
                for habit in habits {
                    let logs = try await logRepository.logs(for: habit.id)
                    let dateLog = logs.first { log in
                        calendar.isDate(log.date, inSameDayAs: startOfDay)
                    }
                    if dateLog != nil {
                        completedCount += 1
                    }
                }
                
                // Calculate completion percentage
                let completionRate = Double(completedCount) / Double(habits.count)
                completionData[startOfDay] = completionRate
            }
        }
        
        return completionData
    }
    
    private func resetDismissedTriggersIfNewDay() {
        let calendar = Calendar.current
        let today = Date()
        
        // Check if we've moved to a new day since last session
        if let lastResetDate = UserDefaults.standard.object(forKey: "lastInspirationResetDate") as? Date {
            if !calendar.isDate(lastResetDate, inSameDayAs: today) {
                dismissedTriggersToday.removeAll()
                UserDefaults.standard.set(today, forKey: "lastInspirationResetDate")
            } else {
                // Load dismissed triggers for today from UserDefaults
                if let dismissedData = UserDefaults.standard.data(forKey: "dismissedTriggersToday"),
                   let dismissedArray = try? JSONDecoder().decode([String].self, from: dismissedData) {
                    dismissedTriggersToday = Set(dismissedArray.compactMap { triggerString in
                        InspirationTrigger.allCases.first { "\($0)" == triggerString }
                    })
                }
            }
        } else {
            // First time - set today as reset date
            UserDefaults.standard.set(today, forKey: "lastInspirationResetDate")
        }
    }
    
    private func saveDismissedTriggers() {
        let dismissedArray = dismissedTriggersToday.map { "\($0)" }
        if let data = try? JSONEncoder().encode(dismissedArray) {
            UserDefaults.standard.set(data, forKey: "dismissedTriggersToday")
        }
    }
    
    // MARK: - Personalized Inspiration Messages
    
    private func getPersonalizedMessage(for trigger: InspirationTrigger) -> String {
        switch trigger {
        case .sessionStart:
            return getSessionStartMessage()
        case .morningMotivation:
            return getMorningMotivationMessage()
        case .firstHabitComplete:
            return getFirstHabitMessage()
        case .halfwayPoint:
            return getHalfwayPointMessage()
        case .strugglingMidDay:
            return getStrugglingMidDayMessage()
        case .afternoonPush:
            return getAfternoonPushMessage()
        case .strongFinish:
            return getStrongFinishMessage()
        case .perfectDay:
            return getPerfectDayMessage()
        case .eveningReflection:
            return getEveningReflectionMessage()
        case .weekendMotivation:
            return getWeekendMotivationMessage()
        case .comebackStory:
            return getComebackStoryMessage()
        }
    }
    
    private var userName: String? {
        let name = userService.currentProfile.name
        return name.isEmpty ? nil : name
    }
    
    private func getSessionStartMessage() -> String {
        if let name = userName {
            switch currentTimeOfDay {
            case .morning:
                return "Good morning, \(name)! Ready to make today incredible?"
            case .noon:
                return "Hey \(name)! Time to power through the day with purpose."
            case .evening:
                return "Evening, \(name)! Let's finish strong together."
            }
        } else {
            switch currentTimeOfDay {
            case .morning:
                return "Welcome back! Ready to start your day with intention?"
            case .noon:
                return "Time to refocus and make the most of your day!"
            case .evening:
                return "Let's finish this day on a powerful note!"
            }
        }
    }
    
    private func getMorningMotivationMessage() -> String {
        if let name = userName {
            return "Rise and shine, \(name)! Every great day starts with the first habit. You've got this! 🌅"
        } else {
            return "Morning energy is powerful energy! Start with one habit and watch the momentum build. 🌅"
        }
    }
    
    private func getFirstHabitMessage() -> String {
        if let name = userName {
            return "Fantastic start, \(name)! One habit down, momentum building. Keep the energy flowing! ⚡"
        } else {
            return "Excellent! Your first habit is complete. Feel that momentum? Let's keep it going! ⚡"
        }
    }
    
    private func getHalfwayPointMessage() -> String {
        if let name = userName {
            return "You're crushing it, \(name)! Halfway there and showing incredible consistency. 🎯"
        } else {
            return "Amazing progress! You're at the halfway mark. Your consistency is paying off! 🎯"
        }
    }
    
    private func getStrugglingMidDayMessage() -> String {
        if let name = userName {
            return "Hey \(name), midday can be tough, but you're tougher. One small step forward is all it takes. 💪"
        } else {
            return "Midday slump? No problem! You have the strength to push through. One habit at a time. 💪"
        }
    }
    
    private func getAfternoonPushMessage() -> String {
        if let name = userName {
            return "\(name), the afternoon is your time to shine! Turn up the energy and finish strong. 🔥"
        } else {
            return "Afternoon energy boost! This is your moment to accelerate and make it count. 🔥"
        }
    }
    
    private func getStrongFinishMessage() -> String {
        if let name = userName {
            return "\(name), you're absolutely on fire! So close to perfection. Let's make it happen! 🌟"
        } else {
            return "You're on fire today! Outstanding progress. Victory is within reach! 🌟"
        }
    }
    
    private func getPerfectDayMessage() -> String {
        if let name = userName {
            return "\(name), you did it! Perfect day achieved! Your dedication is truly inspiring!"
        } else {
            return "Perfect day complete! You've shown incredible dedication and consistency!"
        }
    }
    
    private func getEveningReflectionMessage() -> String {
        if let name = userName {
            return "Beautiful work today, \(name)! Your consistent effort is building something amazing. 🌙"
        } else {
            return "What a productive day! Your commitment to growth is truly admirable. 🌙"
        }
    }
    
    private func getWeekendMotivationMessage() -> String {
        if let name = userName {
            return "Weekend warrior mode, \(name)! Your dedication even on weekends sets you apart. 🏆"
        } else {
            return "Weekend dedication is next level! Your consistency knows no boundaries. 🏆"
        }
    }
    
    private func getComebackStoryMessage() -> String {
        if let name = userName {
            return "\(name), what a comeback! Yesterday was tough, but look at you now. This is resilience! 🚀"
        } else {
            return "Incredible comeback story! You've bounced back stronger than ever. Pure resilience! 🚀"
        }
    }
}
