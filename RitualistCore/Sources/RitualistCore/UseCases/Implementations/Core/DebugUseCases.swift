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
        testDataUtilities: TestDataPopulationServiceProtocol
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
    }
    
    public func execute() async throws {
        // Business workflow orchestration belongs in UseCase, not Service
        
        // Step 1: Clear existing data
        progressUpdate?("Clearing existing data...", 0.0)
        try await debugService.clearDatabase()
        
        // Step 2: Create custom categories
        progressUpdate?("Creating custom categories...", 0.15)
        let customCategories = try await createCustomCategories()
        
        // Step 3: Create habits from suggestions (diverse selection)
        progressUpdate?("Creating habits from suggestions...", 0.3)
        let suggestedHabits = try await createSuggestedHabits()
        
        // Step 4: Create custom habits
        progressUpdate?("Creating custom habits...", 0.5)
        let customHabits = try await createCustomHabits(using: customCategories)
        
        // Step 5: Generate historical data
        progressUpdate?("Generating historical data...", 0.7)
        let allHabits = suggestedHabits + customHabits
        try await generateHistoricalData(for: allHabits)
        
        progressUpdate?("Test data population complete!", 1.0)
    }
    
    // MARK: - Private Business Logic Implementation
    
    private func createCustomCategories() async throws -> [HabitCategory] {
        let customCategoryData = testDataUtilities.getCustomCategoryData()
        var createdCategories: [HabitCategory] = []
        
        for (index, categoryData) in customCategoryData.enumerated() {
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
    
    private func createSuggestedHabits() async throws -> [Habit] {
        let allSuggestions = habitSuggestionsService.getSuggestions()
        guard !allSuggestions.isEmpty else {
            throw TestDataPopulationError("No habit suggestions available")
        }
        
        // Select diverse habits from different categories (2-3 per category max)
        let suggestionsByCategory = Dictionary(grouping: allSuggestions) { $0.categoryId }
        var selectedSuggestions: [HabitSuggestion] = []
        
        for (_, suggestions) in suggestionsByCategory {
            let shuffled = suggestions.shuffled()
            let count = min(3, suggestions.count)
            selectedSuggestions.append(contentsOf: Array(shuffled.prefix(count)))
        }
        
        let finalSuggestions = Array(selectedSuggestions.shuffled().prefix(12))
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
                print("Failed to create habit from suggestion '\(suggestion.name)': \(error)")
            case .limitReached:
                throw TestDataPopulationError("Habit creation limit reached while creating suggested habits")
            }
        }
        
        return createdHabits
    }
    
    private func createCustomHabits(using customCategories: [HabitCategory]) async throws -> [Habit] {
        guard customCategories.count >= 3 else {
            throw TestDataPopulationError("Need at least 3 custom categories to create custom habits")
        }
        
        let customHabitData = testDataUtilities.getCustomHabitData()
        var createdHabits: [Habit] = []
        
        for (index, habitData) in customHabitData.enumerated() {
            let category = customCategories[index]
            
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
            
            try await habitRepository.create(habit)
            createdHabits.append(habit)
        }
        
        return createdHabits
    }
    
    private func generateHistoricalData(for habits: [Habit]) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let dateRange = Array((0..<90).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.reversed())
        
        // Use utility service for pattern calculations
        let dailyCompletionRates = testDataUtilities.generateDailyCompletionRates(
            for: dateRange,
            calendar: calendar
        )
        
        for (dayIndex, date) in dateRange.enumerated() {
            guard let dailyCompletionRate = dailyCompletionRates[date] else { continue }
            
            let progressForDate = 0.7 + (Double(dayIndex) / Double(dateRange.count)) * 0.25
            let weekNumber = (dateRange.count - dayIndex - 1) / 7 + 1
            progressUpdate?("Creating 3-month history: Week \(weekNumber)...", progressForDate)
            
            let scheduledHabits = habits.filter { habit in
                habitCompletionService.isScheduledDay(habit: habit, date: date)
            }
            
            guard !scheduledHabits.isEmpty else { continue }
            
            let targetCompletions = Int(round(Double(scheduledHabits.count) * dailyCompletionRate))
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
                
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: date,
                    value: logValue
                )
                
                try await logHabitUseCase.execute(log)
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