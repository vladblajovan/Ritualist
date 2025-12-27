import Foundation

#if DEBUG
// MARK: - Debug Use Case Implementations

public final class GetDatabaseStats: GetDatabaseStatsUseCase {
    private let debugService: DebugServiceProtocol

    public init(debugService: DebugServiceProtocol) {
        self.debugService = debugService
    }

    public func execute() async throws -> DebugDatabaseStats {
        try await debugService.getDatabaseStats()
    }
}

public final class ClearDatabase: ClearDatabaseUseCase {
    private let debugService: DebugServiceProtocol

    public init(debugService: DebugServiceProtocol) {
        self.debugService = debugService
    }

    public func execute() async throws {
        try await debugService.clearDatabase()
    }
}

public final class PopulateTestData: PopulateTestDataUseCase {
    // MARK: - Dependencies - UseCases and Repositories, NOT Services
    private let debugService: DebugServiceProtocol
    private let habitSuggestionsService: HabitSuggestionsService
    private let createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase
    private let createCustomCategoryUseCase: CreateCustomCategoryUseCase
    private let logHabitUseCase: LogHabitUseCase
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let habitCompletionService: HabitCompletionService
    private let testDataUtilities: TestDataPopulationServiceProtocol
    private let completeOnboardingUseCase: CompleteOnboardingUseCase
    private let logger: DebugLogger

    // MARK: - Progress Tracking
    public var progressUpdate: ((String, Double) -> Void)?

    public init(
        debugService: DebugServiceProtocol,
        habitSuggestionsService: HabitSuggestionsService,
        createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase,
        createCustomCategoryUseCase: CreateCustomCategoryUseCase,
        logHabitUseCase: LogHabitUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        habitCompletionService: HabitCompletionService,
        testDataUtilities: TestDataPopulationServiceProtocol,
        completeOnboardingUseCase: CompleteOnboardingUseCase,
        logger: DebugLogger
    ) {
        self.debugService = debugService
        self.habitSuggestionsService = habitSuggestionsService
        self.createHabitFromSuggestionUseCase = createHabitFromSuggestionUseCase
        self.createCustomCategoryUseCase = createCustomCategoryUseCase
        self.logHabitUseCase = logHabitUseCase
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.habitCompletionService = habitCompletionService
        self.testDataUtilities = testDataUtilities
        self.completeOnboardingUseCase = completeOnboardingUseCase
        self.logger = logger
    }
    
    public func execute(scenario: TestDataScenario = .full) async throws {
        // Get configuration for the selected scenario
        let config = TestDataScenarioConfig.config(for: scenario)

        // Business workflow orchestration belongs in UseCase, not Service

        // Step 1: Clear existing data
        progressUpdate?("Clearing existing data...", 0.0)
        try await debugService.clearDatabase()

        // Step 2: Create custom categories (scenario-dependent count)
        progressUpdate?("Creating custom categories...", 0.15)
        let customCategories = try await createCustomCategories(count: config.customCategoryCount, scenario: scenario)

        // Step 3: Create habits from suggestions (scenario-dependent count)
        progressUpdate?("Creating habits from suggestions...", 0.3)
        let suggestedHabits = try await createSuggestedHabits(count: config.suggestedHabitCount)

        // Step 4: Create custom habits (scenario-dependent count)
        progressUpdate?("Creating custom habits...", 0.5)
        let customHabits = try await createCustomHabits(
            count: config.customHabitCount,
            using: customCategories,
            scenario: scenario
        )

        // Step 5: Generate historical data (scenario-dependent days and completion)
        progressUpdate?("Generating \(config.historyDays)-day history...", 0.7)

        // CRITICAL FIX: Re-fetch all habits from database to ensure context sync
        // The @ModelActor isolation means created habits might not be immediately
        // visible to subsequent queries. Force a fresh fetch to guarantee we see
        // all persisted habits before generating logs.
        let persistedHabits = try await habitRepository.fetchAllHabits()

        // STREAK FIX: Update habit startDate to match historical data range
        // Without this, streak calculation only looks back to habit.startDate (TODAY)
        // while logs go back config.historyDays, resulting in streak = 1
        let historicalStartDate = CalendarUtils.addDays(-config.historyDays, to: CalendarUtils.startOfDayLocal(for: Date()))
        for habit in persistedHabits {
            var updatedHabit = habit
            updatedHabit.startDate = historicalStartDate
            try await habitRepository.update(updatedHabit)
        }

        // Re-fetch to get updated habits with correct startDate
        let updatedPersistedHabits = try await habitRepository.fetchAllHabits()

        try await generateHistoricalData(
            for: updatedPersistedHabits,
            days: config.historyDays,
            completionRange: config.completionRateRange
        )

        // Step 6: Complete onboarding with test user profile
        progressUpdate?("Setting up user profile...", 0.95)
        try await completeOnboardingUseCase.execute(
            userName: "Test User",
            hasNotifications: false,
            hasLocation: false,
            gender: nil,
            ageGroup: nil
        )

        progressUpdate?("\(scenario.rawValue) data complete!", 1.0)
    }
    
    // MARK: - Private Business Logic Implementation

    private func createCustomCategories(count: Int, scenario: TestDataScenario) async throws -> [HabitCategory] {
        // Use personality-specific categories for personality profile scenarios
        let customCategoryData: [(name: String, displayName: String, emoji: String)]
        switch scenario {
        case .opennessProfile, .conscientiousnessProfile, .extraversionProfile, .agreeablenessProfile, .neuroticismProfile:
            customCategoryData = testDataUtilities.getPersonalityCategories(for: scenario)
        case .minimal, .moderate, .full:
            customCategoryData = testDataUtilities.getCustomCategoryData()
        }

        var createdCategories: [HabitCategory] = []

        // Take only the requested number of categories
        let categoriesToCreate = Array(customCategoryData.prefix(count))

        for (index, categoryData) in categoriesToCreate.enumerated() {
            let category = HabitCategory(
                id: UUID().uuidString,
                name: categoryData.name,
                displayName: categoryData.displayName,
                emoji: categoryData.emoji,
                order: 100 + index,
                isActive: true,
                isPredefined: false
            )
            try await createCustomCategoryUseCase.execute(category)
            createdCategories.append(category)
        }

        return createdCategories
    }
    
    private func createSuggestedHabits(count: Int) async throws -> [Habit] {
        let allSuggestions = habitSuggestionsService.getSuggestions()
        guard !allSuggestions.isEmpty else {
            throw TestDataPopulationError("No habit suggestions available")
        }

        // Select diverse habits from different categories (2-3 per category max)
        let suggestionsByCategory = Dictionary(grouping: allSuggestions) { $0.categoryId }
        var selectedSuggestions: [HabitSuggestion] = []

        for (_, suggestions) in suggestionsByCategory {
            let shuffled = suggestions.shuffled()
            let maxPerCategory = min(3, suggestions.count)
            selectedSuggestions.append(contentsOf: Array(shuffled.prefix(maxPerCategory)))
        }

        // Take only the requested number of suggestions
        let finalSuggestions = Array(selectedSuggestions.shuffled().prefix(count))
        var createdHabits: [Habit] = []

        for suggestion in finalSuggestions {
            let result = await createHabitFromSuggestionUseCase.execute(suggestion)

            switch result {
            case .success(let habitId):
                if let habits = try? await habitRepository.fetchAllHabits(),
                   let habit = habits.first(where: { $0.id == habitId }) {
                    createdHabits.append(habit)
                }
            case .error(let error):
                logger.log("Failed to create habit from suggestion '\(suggestion.name)': \(error)", level: .error, category: .debug)
            case .limitReached:
                throw TestDataPopulationError("Habit creation limit reached while creating suggested habits")
            }
        }

        return createdHabits
    }
    
    private func createCustomHabits(count: Int, using customCategories: [HabitCategory], scenario: TestDataScenario) async throws -> [Habit] {
        // If no custom categories available, return empty array
        guard !customCategories.isEmpty else {
            return []
        }

        // Use personality-specific habits for personality profile scenarios
        let customHabitData: [(name: String, emoji: String, colorHex: String, kind: HabitKind, unitLabel: String?, dailyTarget: Double?, schedule: HabitSchedule)]
        switch scenario {
        case .opennessProfile, .conscientiousnessProfile, .extraversionProfile, .agreeablenessProfile, .neuroticismProfile:
            customHabitData = testDataUtilities.getPersonalityHabits(for: scenario)
        case .minimal, .moderate, .full:
            customHabitData = testDataUtilities.getCustomHabitData()
        }

        var createdHabits: [Habit] = []

        // Take only the requested number of habits
        let habitsToCreate = Array(customHabitData.prefix(count))

        for (index, habitData) in habitsToCreate.enumerated() {
            // Cycle through available categories if we have more habits than categories
            let category = customCategories[index % customCategories.count]

            let habit = Habit(
                id: UUID(),
                name: habitData.name,
                colorHex: habitData.colorHex,
                emoji: habitData.emoji,
                kind: habitData.kind,
                unitLabel: habitData.unitLabel,
                dailyTarget: habitData.dailyTarget,
                schedule: habitData.schedule,
                isActive: true,
                categoryId: category.id
            )

            try await habitRepository.update(habit)
            createdHabits.append(habit)
        }

        return createdHabits
    }
    
    private func generateHistoricalData(
        for habits: [Habit],
        days: Int,
        completionRange: ClosedRange<Double>
    ) async throws {
        // Use LOCAL timezone to match production behavior and PersonalityAnalysisRepositoryImpl
        // Test data should appear natural in the app UI, using the same LOCAL logic as real users
        let today = CalendarUtils.startOfDayLocal(for: Date())

        let dateRange = Array((0..<days).compactMap { dayOffset in
            CalendarUtils.addDays(-dayOffset, to: today)
        }.reversed())

        // Use utility service for pattern calculations
        // For minimal scenarios, use simpler completion patterns
        let dailyCompletionRates: [Date: Double]
        if days <= 7 {
            // Simple patterns for short history
            dailyCompletionRates = dateRange.reduce(into: [:]) { dict, date in
                dict[date] = Double.random(in: completionRange)
            }
        } else {
            // Sophisticated patterns for longer history
            dailyCompletionRates = testDataUtilities.generateDailyCompletionRates(
                for: dateRange
            )
        }
        
        for (dayIndex, date) in dateRange.enumerated() {
            guard let dailyCompletionRate = dailyCompletionRates[date] else { continue }

            let progressForDate = 0.7 + (Double(dayIndex) / Double(dateRange.count)) * 0.25

            // Update progress message based on scenario size
            if days <= 7 {
                let dayNumber = dayIndex + 1
                progressUpdate?("Creating \(days)-day history: Day \(dayNumber)/\(days)...", progressForDate)
            } else {
                let weekNumber = (dateRange.count - dayIndex - 1) / 7 + 1
                let totalWeeks = (days + 6) / 7
                progressUpdate?("Creating \(days)-day history: Week \(weekNumber)/\(totalWeeks)...", progressForDate)
            }
            
            let scheduledHabits = habits.filter { habit in
                habitCompletionService.isScheduledDay(habit: habit, date: date)
            }

            guard !scheduledHabits.isEmpty else { continue }

            // CRITICAL: Ensure at least ONE log per day for consecutive tracking validation
            // The PersonalityAnalysisRepositoryImpl requires logs on consecutive days
            let targetCompletions = max(1, Int(round(Double(scheduledHabits.count) * dailyCompletionRate)))
            let shuffledHabits = scheduledHabits.shuffled()
            let habitsToComplete = Array(shuffledHabits.prefix(targetCompletions))
            
            for habit in habitsToComplete {
                let logValue: Double?
                
                switch habit.kind {
                case .binary:
                    logValue = 1.0
                    
                case .numeric:
                    if let target = habit.dailyTarget {
                        let variation = Double.random(in: 0.9...1.1)
                        logValue = target * variation
                    } else {
                        logValue = Double.random(in: 1.0...10.0)
                    }
                }

                // Keep the log timestamp within the same LOCAL day for realistic test data
                // Use LOCAL timezone to match production behavior and PersonalityAnalysisRepositoryImpl
                // This ensures test data appears correctly in the app UI

                let baseHour = Int.random(in: 8...20) // Realistic logging hours: 8 AM to 8 PM local time
                let randomMinutes = Int.random(in: 0...59)

                // Extract LOCAL components from the LOCAL date
                var components = CalendarUtils.currentLocalCalendar.dateComponents([.year, .month, .day], from: date)
                components.hour = baseHour
                components.minute = randomMinutes
                components.second = 0
                components.timeZone = TimeZone.current

                let finalTimestamp = CalendarUtils.currentLocalCalendar.date(from: components) ?? date

                // CRITICAL FIX: Use direct initializer, NOT withCurrentTimezone
                // withCurrentTimezone() ignores the date parameter and always uses Date.now
                // We need to use our historical finalTimestamp, not current time
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: finalTimestamp,
                    value: logValue,
                    timezone: TimeZone.current.identifier  // Use current timezone for realistic test data
                )
                
                do {
                    try await logHabitUseCase.execute(log)
                } catch let error as HabitScheduleValidationError {
                    // Log detailed error information for debugging
                    logger.log("Schedule validation failed for '\(habit.name)' - Original: \(date), Final: \(finalTimestamp), Schedule: \(habit.schedule), isScheduledDay(original): \(habitCompletionService.isScheduledDay(habit: habit, date: date)), isScheduledDay(final): \(habitCompletionService.isScheduledDay(habit: habit, date: finalTimestamp)), Error: \(error.localizedDescription)", level: .warning, category: .debug)

                    // Don't re-throw - just skip this log and continue with next habit
                    continue
                } catch {
                    logger.log("Unexpected error logging '\(habit.name)': \(error)", level: .error, category: .debug)
                    continue
                }
            }
        }
    }
}

// Test Data Population Error
public struct TestDataPopulationError: LocalizedError {
    public let message: String
    
    public var errorDescription: String? { message }
    
    public init(_ message: String) {
        self.message = message
    }
}

#endif