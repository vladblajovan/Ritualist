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

public final class PopulateTestData: PopulateTestDataUseCase, @unchecked Sendable {
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
    private let seedPredefinedCategoriesUseCase: SeedPredefinedCategoriesUseCase
    private let userDefaults: UserDefaultsService
    private let logger: DebugLogger

    // MARK: - Progress Tracking
    // Debug-only code: mutable for progress updates, @unchecked Sendable is acceptable
    nonisolated(unsafe) public var progressUpdate: (@Sendable (String, Double) -> Void)?

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
        seedPredefinedCategoriesUseCase: SeedPredefinedCategoriesUseCase,
        userDefaults: UserDefaultsService = DefaultUserDefaultsService(),
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
        self.seedPredefinedCategoriesUseCase = seedPredefinedCategoriesUseCase
        self.userDefaults = userDefaults
        self.logger = logger
    }
    
    public func execute(scenario: TestDataScenario = .full) async throws {
        // Get configuration for the selected scenario
        let config = TestDataScenarioConfig.config(for: scenario)

        // Business workflow orchestration belongs in UseCase, not Service

        // Step 1: Clear existing data
        progressUpdate?("Clearing existing data...", 0.0)
        try await debugService.clearDatabase()

        // Step 1.5: Re-seed predefined categories
        // clearDatabase() deletes all categories but doesn't reset the seeding flag.
        // We must reset the flag and re-seed so habits from suggestions have valid category relationships.
        progressUpdate?("Seeding predefined categories...", 0.1)
        userDefaults.removeObject(forKey: UserDefaultsKeys.categorySeedingCompleted)
        try await seedPredefinedCategoriesUseCase.execute()

        // Step 2: Create custom categories (scenario-dependent count)
        progressUpdate?("Creating custom categories...", 0.2)
        let customCategories = try await createCustomCategories(count: config.customCategoryCount, scenario: scenario)

        // Step 3: Create habits from suggestions (scenario-dependent count and categories)
        progressUpdate?("Creating habits from suggestions...", 0.3)
        let suggestedHabits = try await createSuggestedHabits(count: config.suggestedHabitCount, scenario: scenario)

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
    
    private func createSuggestedHabits(count: Int, scenario: TestDataScenario) async throws -> [Habit] {
        // Pass nil for demographics to get ALL suggestions for test data
        let allSuggestions = habitSuggestionsService.getSuggestions(gender: nil, ageGroup: nil)
        guard !allSuggestions.isEmpty else {
            throw TestDataPopulationError("No habit suggestions available")
        }

        let suggestionsByCategory = Dictionary(grouping: allSuggestions) { $0.categoryId }
        let categoryDistribution = getCategoryDistribution(for: scenario, totalCount: count)

        var selectedSuggestions: [HabitSuggestion] = []

        // Select habits according to the explicit category distribution
        for (categoryId, targetCount) in categoryDistribution {
            guard let suggestions = suggestionsByCategory[categoryId] else { continue }
            let shuffled = suggestions.shuffled()
            selectedSuggestions.append(contentsOf: shuffled.prefix(targetCount))
        }

        // Take only the requested number (in case distribution added extras)
        let finalSuggestions = Array(selectedSuggestions.prefix(count))
        var createdHabits: [Habit] = []

        // NOTE: CreateHabitFromSuggestionUseCase no longer checks limits.
        // Limit checking is now at the UI layer, so test data can create unlimited habits.
        for suggestion in finalSuggestions {
            let result = await createHabitFromSuggestionUseCase.execute(suggestion)

            switch result {
            case .success(let habitId):
                if let habits = try? await habitRepository.fetchAllHabits(),
                   let habit = habits.first(where: { $0.id == habitId }) {
                    createdHabits.append(habit)
                }
            case .alreadyExists:
                // Skip - habit already exists, don't count as newly created test data
                break
            case .error(let error):
                logger.log("Failed to create habit from suggestion '\(suggestion.name)': \(error)", level: .error, category: .debug)
            }
        }

        return createdHabits
    }

    /// Returns explicit category distribution for each scenario
    /// This ensures deterministic personality outcomes by controlling exactly which categories habits come from
    /// Key: categoryId, Value: number of habits to create from that category
    private func getCategoryDistribution(for scenario: TestDataScenario, totalCount: Int) -> [String: Int] {
        switch scenario {
        // PERSONALITY PROFILE SCENARIOS
        // Each uses specific category mix to produce the target dominant trait

        case .opennessProfile:
            // Target: High Openness
            // Learning (openness: 0.8) + Creativity (openness: 0.9) = strongest openness signal
            // Distribution: ~50% learning, ~50% creativity
            let half = totalCount / 2
            return [
                "learning": half,
                "creativity": totalCount - half
            ]

        case .conscientiousnessProfile:
            // Target: High Conscientiousness
            // Productivity (conscientiousness: 0.8) + Health (conscientiousness: 0.6)
            // Distribution: ~60% productivity (higher weight), ~40% health
            let productivity = Int(Double(totalCount) * 0.6)
            return [
                "productivity": productivity,
                "health": totalCount - productivity
            ]

        case .extraversionProfile:
            // Target: High Extraversion
            // Social (extraversion: 0.7) is the only category with high extraversion
            // Use 100% social habits to maximize extraversion signal
            return [
                "social": totalCount
            ]

        case .agreeablenessProfile:
            // Target: High Agreeableness
            // Social (agreeableness: 0.6, BUT extraversion: 0.7) + Wellness (agreeableness: 0.2)
            // Using ~40% social, ~60% wellness dilutes extraversion while accumulating agreeableness
            // This ensures agreeableness beats extraversion
            let social = Int(Double(totalCount) * 0.4)
            return [
                "social": social,
                "wellness": totalCount - social
            ]

        case .neuroticismProfile:
            // Target: High Neuroticism (via very low completion rate triggering instability)
            // Use 100% Health category - it has NO openness weight (unlike Wellness)
            // Wellness has openness: 0.3 which would compete with neuroticism signal
            // Health only has: conscientiousness: 0.6, neuroticism: -0.3, agreeableness: 0.2
            // The algorithm triggers strong neuroticism when completion < 30%
            return [
                "health": totalCount
            ]

        // GENERAL SCENARIOS
        // These create balanced or diverse habit mixes

        case .full:
            // Power User: Balanced profile across ALL categories
            // Equal distribution produces balanced personality scores
            let perCategory = totalCount / 6
            let remainder = totalCount % 6
            return [
                "health": perCategory + (remainder > 0 ? 1 : 0),
                "wellness": perCategory + (remainder > 1 ? 1 : 0),
                "productivity": perCategory + (remainder > 2 ? 1 : 0),
                "learning": perCategory + (remainder > 3 ? 1 : 0),
                "social": perCategory + (remainder > 4 ? 1 : 0),
                "creativity": perCategory
            ]

        case .moderate:
            // Building Momentum: Diverse selection (2-3 per category, some variety)
            // Slightly favor health/productivity as common starting points
            return [
                "health": 2,
                "wellness": 1,
                "productivity": 2,
                "learning": 1,
                "social": 0,
                "creativity": 0
            ]

        case .minimal:
            // Fresh Start: Very few habits, common beginner choices
            return [
                "health": 2,
                "productivity": 1
            ]
        }
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