import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// swiftlint:disable file_length type_body_length

// MARK: - Data Models (moved to RitualistCore)

// MARK: - ViewModel

@MainActor
@Observable
public final class OverviewV2ViewModel {
    // MARK: - Observable Properties
    public var todaysSummary: TodaysSummary?
    public var weeklyProgress: WeeklyProgress?
    public var activeStreaks: [StreakInfo] = []
    public var smartInsights: [SmartInsight] = []
    public var personalityInsights: [OverviewPersonalityInsight] = []
    public var shouldShowPersonalityInsights = true // Always show the card
    public var isPersonalityDataSufficient = false // Track if data is sufficient for new analysis
    public var personalityThresholdRequirements: [ThresholdRequirement] = [] // Current requirements status
    public var dominantPersonalityTrait: String? = nil
    public var selectedDate: Date = Date()
    public var isCalendarExpanded: Bool = false
    public var viewingDate: Date = Date() // The date being viewed in Today's Progress card
    public var showInspirationCard: Bool = false
    
    // Inspiration card tracking
    @ObservationIgnored private var lastShownInspirationTrigger: InspirationTrigger?
    @ObservationIgnored private var sessionStartTime: Date = Date()
    @ObservationIgnored private var dismissedTriggersToday: Set<InspirationTrigger> = []
    
    public var isLoading: Bool = false
    public var error: Error?
    
    // Shared sheet state
    public var selectedHabitForSheet: Habit?
    public var showingNumericSheet = false
    
    // Progress cache - single source of truth for habit progress
    @ObservationIgnored private var habitProgressCache: [UUID: Double] = [:]
    
    // MARK: - Computed Properties
    public var incompleteHabits: [Habit] {
        todaysSummary?.incompleteHabits ?? []
    }
    
    public var completedHabits: [Habit] {
        todaysSummary?.completedHabits ?? []
    }
    
    public var shouldShowQuickActions: Bool {
        // Show QuickActions when there are incomplete habits OR completed habits to display
        return !incompleteHabits.isEmpty || !completedHabits.isEmpty
    }
    
    public var shouldShowActiveStreaks: Bool {
        !activeStreaks.isEmpty
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
    
    // InspirationTrigger moved to RitualistCore/Enums/MotivationEnums.swift
    private typealias InspirationTrigger = RitualistCore.InspirationTrigger
    
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
    
    public var monthlyCompletionData: [Date: Double] = [:]
    
    // MARK: - Dependencies
    @ObservationIgnored @Injected(\.getActiveHabits) private var getActiveHabits
    @ObservationIgnored @Injected(\.getLogs) private var getLogs
    @ObservationIgnored @Injected(\.getBatchLogs) private var getBatchLogs
    @ObservationIgnored @Injected(\.logHabit) private var logHabit
    @ObservationIgnored @Injected(\.deleteLog) private var deleteLog
    @ObservationIgnored @Injected(\.slogansService) private var slogansService
    @ObservationIgnored @Injected(\.userService) private var userService
    @ObservationIgnored @Injected(\.calculateCurrentStreak) private var calculateCurrentStreakUseCase
    @ObservationIgnored @Injected(\.getPersonalityProfileUseCase) private var getPersonalityProfileUseCase
    @ObservationIgnored @Injected(\.getPersonalityInsightsUseCase) private var getPersonalityInsightsUseCase
    @ObservationIgnored @Injected(\.updatePersonalityAnalysisUseCase) private var updatePersonalityAnalysisUseCase
    @ObservationIgnored @Injected(\.validateAnalysisDataUseCase) private var validateAnalysisDataUseCase
    @ObservationIgnored @Injected(\.personalityAnalysisRepository) private var personalityAnalysisRepository
    @ObservationIgnored @Injected(\.personalityDeepLinkCoordinator) private var personalityDeepLinkCoordinator
    
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
            async let preloadHabitDataTask = preloadHabitData()
            
            let (todaySummary, weeklyProgress, streaks, insights, monthlyData, _) = try await (
                todaySummaryTask,
                weeklyProgressTask,
                activeStreaksTask,
                insightsTask,
                monthlyDataTask,
                preloadHabitDataTask
            )
            
            // Load personality insights separately (non-blocking)
            Task {
                await loadPersonalityInsights()
            }
            
            self.todaysSummary = todaySummary
            self.weeklyProgress = weeklyProgress
            self.activeStreaks = streaks
            self.smartInsights = insights
            self.monthlyCompletionData = monthlyData
            
            // Check if we should show inspiration card contextually
            self.checkAndShowInspirationCard()
            
        } catch {
            self.error = error
            print("Failed to load OverviewV2 data: \(error)")
        }
        
        self.isLoading = false
    }
    
    public func refresh() async {
        await loadData()
    }
    
    public func openPersonalityAnalysis() {
        personalityDeepLinkCoordinator.showPersonalityAnalysisDirectly()
    }
    
    public func refreshPersonalityInsights() async {
        await loadPersonalityInsights()
    }
    
    public func completeHabit(_ habit: Habit) async {
        do {
            if habit.kind == .numeric {
                // For numeric habits, set to daily target (this should primarily be used for binary habits)
                // Most numeric habit interactions should go through updateNumericHabit instead
                await updateNumericHabit(habit, value: habit.dailyTarget ?? 1.0)
            } else {
                // Binary habit - just create a log with value 1.0
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: viewingDate,
                    value: 1.0
                )
                
                try await logHabit.execute(log)
                
                // Refresh data to show updated progress
                await loadData()
            }
            
        } catch {
            self.error = error
            print("Failed to complete habit: \(error)")
        }
    }
    
    public func getCurrentProgress(for habit: Habit) async -> Double {
        do {
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let logsForDate = allLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: viewingDate) }
            
            if habit.kind == .numeric {
                return logsForDate.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            } else {
                return logsForDate.isEmpty ? 0.0 : 1.0
            }
        } catch {
            print("Failed to get current progress for habit \(habit.name): \(error)")
            return 0.0
        }
    }
    
    
    public func updateNumericHabit(_ habit: Habit, value: Double) async {
        do {
            // Get existing logs for this habit on the viewing date
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let existingLogsForDate = allLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: viewingDate) }
            
            if existingLogsForDate.isEmpty {
                // No existing log for this date - create new one
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: viewingDate,
                    value: value
                )
                try await logHabit.execute(log)
            } else if existingLogsForDate.count == 1 {
                // Single existing log - update it
                var updatedLog = existingLogsForDate[0]
                updatedLog.value = value
                try await logHabit.execute(updatedLog)
                
            } else {
                // Multiple logs exist for this date - this shouldn't happen for our UI
                // But let's handle it properly: delete all existing logs and create one new log
                for existingLog in existingLogsForDate {
                    try await deleteLog.execute(id: existingLog.id)
                }
                
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: viewingDate,
                    value: value
                )
                try await logHabit.execute(log)
            }
            
            // Update progress cache immediately for responsive UI
            habitProgressCache[habit.id] = value
            
            // Refresh data to show updated progress and completion status
            await loadData()
            
        } catch {
            self.error = error
            print("Failed to update numeric habit: \(error)")
        }
    }
    
    public func getProgressSync(for habit: Habit) -> Double {
        return habitProgressCache[habit.id] ?? 0.0
    }
    
    public func showNumericSheet(for habit: Habit) {
        selectedHabitForSheet = habit
        showingNumericSheet = true
    }
    
    public func deleteHabitLog(_ habit: Habit) async {
        do {
            // Get existing logs for this habit on the viewing date
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let existingLogsForDate = allLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: viewingDate) }
            
            // Delete all logs for this habit on this date
            for log in existingLogsForDate {
                try await deleteLog.execute(id: log.id)
            }
            
            // Refresh data to show updated UI
            await loadData()
            
        } catch {
            self.error = error
            print("Failed to delete habit log: \(error)")
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
            let yesterdayHabits = try await getActiveHabits.execute()
            var yesterdayCompletedCount = 0
            
            for habit in yesterdayHabits {
                let logs = try await getLogs.execute(for: habit.id, since: yesterday, until: yesterday)
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
            
            if let bestTrigger = selectBestTrigger(from: triggers) {
                showInspirationWithTrigger(bestTrigger)
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
            self.lastShownInspirationTrigger = trigger
            self.showInspirationCard = true
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
        let allActiveHabits = try await getActiveHabits.execute()
        
        let habits = allActiveHabits.filter { habit in
            let isScheduled = habit.schedule.isActiveOn(date: targetDate)
            return isScheduled
        }

        var allTargetDateLogs: [HabitLog] = []
        
        // OPTIMIZATION: Batch load logs for all habits to avoid N+1 queries
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: targetDate, until: targetDate)
        
        for habit in habits {
            let habitLogs = logsByHabitId[habit.id] ?? []
            let targetDateLogs = habitLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
            allTargetDateLogs.append(contentsOf: targetDateLogs)
        }
        
        // Count will be calculated based on the completed habits array
        
        // Create completed habits array (sorted by completion time)
        let completedHabits = habits.filter { habit in
            let habitLogs = allTargetDateLogs.filter { $0.habitID == habit.id }
            
            if habit.kind == .binary {
                // Binary habits: completed if any log exists
                return !habitLogs.isEmpty
            } else {
                // Numeric habits: completed if total value >= daily target
                let totalValue = habitLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                let target = habit.dailyTarget ?? 1.0
                return totalValue >= target
            }
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
            let habitLogs = allTargetDateLogs.filter { $0.habitID == habit.id }
            
            if targetDate > Date() {
                return false // Don't show future dates as incomplete
            }
            
            if habit.kind == .binary {
                // Binary habits: incomplete if no log exists
                return habitLogs.isEmpty
            } else {
                // Numeric habits: incomplete if total value < daily target
                let totalValue = habitLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                let target = habit.dailyTarget ?? 1.0
                return totalValue < target
            }
        }
        
        return TodaysSummary(
            completedHabitsCount: completedHabits.count,
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
                let allActiveHabits = try await getActiveHabits.execute()
                let habits = allActiveHabits.filter { $0.schedule.isActiveOn(date: dayDate) }
                
                // OPTIMIZATION: Batch load logs for all habits to avoid N+1 queries
                let habitIds = habits.map(\.id)
                let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: dayDate, until: dayDate)
                
                var completedCount = 0
                for habit in habits {
                    let logs = logsByHabitId[habit.id] ?? []
                    let dateLog = logs.first { log in
                        calendar.isDate(log.date, inSameDayAs: dayDate)
                    }
                    if dateLog != nil {
                        completedCount += 1
                    }
                }
                
                // Consider day completed ONLY if ALL habits were logged (100%)
                let isCompleted = !habits.isEmpty && Double(completedCount) / Double(habits.count) >= 1.0
                daysCompleted.append(isCompleted)
            } else {
                daysCompleted.append(false)
            }
        }
        
        return WeeklyProgress(daysCompleted: daysCompleted, currentDayIndex: currentDayIndex)
    }
    
    private func loadActiveStreaks() async throws -> [StreakInfo] {
        let habits = try await getActiveHabits.execute()
        var streaks: [StreakInfo] = []
        
        // OPTIMIZATION: Batch load all logs for all habits to avoid N+1 queries
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: nil, until: nil)
        
        for habit in habits {
            // Calculate current streak using cached logs
            let logs = logsByHabitId[habit.id] ?? []
            let today = Date()
            let currentStreak = calculateCurrentStreakUseCase.execute(habit: habit, logs: logs, asOf: today)
            
            if currentStreak >= 1 { // Show all active streaks (1+ days)
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
    
    
    private func loadSmartInsights() async throws -> [SmartInsight] {
        // Smart Insights now only contains basic habit pattern analysis
        return try await generateBasicHabitInsights()
    }
    
    private func loadPersonalityInsights() async {
        do {
            // Always get eligibility and requirements info using the UseCase
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
            
            // Update state with eligibility info
            isPersonalityDataSufficient = eligibility.isEligible
            personalityThresholdRequirements = requirements
            
            // Always show the card now - it will handle different states internally
            shouldShowPersonalityInsights = true
            
            // Get existing personality profile
            var personalityProfile = try await getPersonalityProfileUseCase.execute(for: userId)
            
            // If user is eligible but no profile exists, attempt to create one
            if eligibility.isEligible && personalityProfile == nil {
                do {
                    let newProfile = try await updatePersonalityAnalysisUseCase.execute(for: userId)
                    personalityProfile = newProfile
                } catch {
                    // If analysis fails, we still show the card but with error state
                    personalityInsights = []
                    dominantPersonalityTrait = nil
                    return
                }
            }
            
            // If we have a profile, get insights from it
            if let profile = personalityProfile {
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
                
                personalityInsights = cardInsights
                dominantPersonalityTrait = profile.dominantTrait.displayName
            } else {
                // No profile available (either data insufficient or analysis failed)
                personalityInsights = []
                dominantPersonalityTrait = nil
            }
            
        } catch {
            // Even on error, show the card but with empty state
            personalityInsights = []
            dominantPersonalityTrait = nil
            isPersonalityDataSufficient = false
            personalityThresholdRequirements = []
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
        
        // Get the proper week interval that respects user's first day of week preference
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return insights
        }
        let startOfWeek = weekInterval.start
        
        // Get user's active habits and recent logs
        let habits = try await getActiveHabits.execute()
        guard !habits.isEmpty else {
            return []
        }
        
        // Analyze completion patterns over the past week
        var totalCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)
        
        // OPTIMIZATION: Batch load logs for all habits to avoid N+1 queries
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: startOfWeek, until: weekInterval.end)
        
        for habit in habits {
            let logs = logsByHabitId[habit.id] ?? []
            let recentLogs = logs.filter { log in
                log.date >= startOfWeek && log.date < weekInterval.end
            }
            
            totalCompletions += recentLogs.count
            
            // Count completions per day
            for log in recentLogs {
                let daysSinceStart = calendar.dateComponents([.day], from: startOfWeek, to: log.date).day ?? 0
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
            // Get the actual date for the best performing day
            guard let bestDate = calendar.date(byAdding: .day, value: bestDayIndex, to: startOfWeek) else {
                return insights
            }
            
            // Get the day name using the proper date
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let bestDayName = dayFormatter.string(from: bestDate)
            
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
        let allActiveHabits = try await getActiveHabits.execute()
        guard !allActiveHabits.isEmpty else { return [:] }
        
        var completionData: [Date: Double] = [:]
        
        // Load data for the past 30 days
        for i in 0...30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                
                // FIXED: Apply schedule filtering like other methods
                let habits = allActiveHabits.filter { $0.schedule.isActiveOn(date: startOfDay) }
                
                // Get all logs for this date
                // OPTIMIZATION: Batch load logs for all habits to avoid N+1 queries
                let habitIds = habits.map(\.id)
                let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: startOfDay, until: startOfDay)
                
                var completedCount = 0
                for habit in habits {
                    let logs = logsByHabitId[habit.id] ?? []
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
    
    /// Pre-loads habit data to prevent empty sheets on app start
    private func preloadHabitData() async throws {
        let habits = try await getActiveHabits.execute()
        
        // Pre-fetch and cache progress for all habits to avoid empty sheets
        for habit in habits {
            let logs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let targetDateLogs = logs.filter { Calendar.current.isDate($0.date, inSameDayAs: viewingDate) }
            
            let progress: Double
            if habit.kind == .numeric {
                progress = targetDateLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            } else {
                progress = targetDateLogs.isEmpty ? 0.0 : 1.0
            }
            
            habitProgressCache[habit.id] = progress
        }
    }
}
