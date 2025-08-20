//
//  TestDataPopulationService.swift
//  Ritualist
//
//  Created by Claude on 20.08.2025.
//

import Foundation
import SwiftData
import FactoryKit
import RitualistCore

/// Service for populating test data for debugging and testing
/// Only available in debug builds
public protocol TestDataPopulationServiceProtocol {
    /// Populate comprehensive test data including habits, categories, and historical logs
    func populateTestData() async throws
    
    /// Get progress updates during population
    var progressUpdate: ((String, Double) -> Void)? { get set }
}

public struct TestDataPopulationError: LocalizedError {
    public let message: String
    
    public var errorDescription: String? { message }
    
    public init(_ message: String) {
        self.message = message
    }
}

#if DEBUG
// swiftlint:disable type_body_length
public final class TestDataPopulationService: TestDataPopulationServiceProtocol {
    // MARK: - Dependencies
    private let debugService: DebugServiceProtocol
    private let habitSuggestionsService: HabitSuggestionsService
    private let createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase
    private let createCustomCategoryUseCase: CreateCustomCategoryUseCase
    private let logHabitUseCase: LogHabitUseCase
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let habitCompletionService: HabitCompletionServiceProtocol
    
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
        habitCompletionService: HabitCompletionServiceProtocol
    ) {
        self.debugService = debugService
        self.habitSuggestionsService = habitSuggestionsService
        self.createHabitFromSuggestionUseCase = createHabitFromSuggestionUseCase
        self.createCustomCategoryUseCase = createCustomCategoryUseCase
        self.logHabitUseCase = logHabitUseCase
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.habitCompletionService = habitCompletionService
    }
    
    public func populateTestData() async throws {
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
    
    // MARK: - Private Implementation
    
    private func createCustomCategories() async throws -> [HabitCategory] {
        struct CustomCategoryData {
            let name: String
            let displayName: String
            let emoji: String
        }
        
        // Define custom categories with diverse emojis that align with category purposes
        let customCategoryData = [
            CustomCategoryData(name: "creative_projects", displayName: "Creative Projects", emoji: "🎨"),
            CustomCategoryData(name: "home_improvement", displayName: "Home Improvement", emoji: "🏠"),
            CustomCategoryData(name: "learning_goals", displayName: "Learning Goals", emoji: "🧠")
        ]
        
        var createdCategories: [HabitCategory] = []
        
        for (index, categoryData) in customCategoryData.enumerated() {
            do {
                let category = HabitCategory(
                    id: UUID().uuidString,
                    name: categoryData.name,
                    displayName: categoryData.displayName,
                    emoji: categoryData.emoji,
                    order: 100 + index, // Place after predefined categories
                    isActive: true,
                    isPredefined: false
                )
                try await createCustomCategoryUseCase.execute(category)
                createdCategories.append(category)
            } catch {
                throw TestDataPopulationError("Failed to create custom category '\(categoryData.displayName)': \(error.localizedDescription)")
            }
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
        
        for (categoryId, suggestions) in suggestionsByCategory {
            let shuffled = suggestions.shuffled()
            let count = min(3, suggestions.count) // Max 3 per category
            selectedSuggestions.append(contentsOf: Array(shuffled.prefix(count)))
        }
        
        // Limit total to reasonable number for testing
        let finalSuggestions = Array(selectedSuggestions.shuffled().prefix(12))
        
        var createdHabits: [Habit] = []
        
        for suggestion in finalSuggestions {
            let result = await createHabitFromSuggestionUseCase.execute(suggestion)
            
            switch result {
            case .success(let habitId):
                // Fetch all habits and find the one we just created
                if let habits = try? await habitRepository.fetchAllHabits(),
                   let habit = habits.first(where: { $0.id == habitId }) {
                    createdHabits.append(habit)
                }
            case .error(let error):
                // Log but continue with other habits
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
        
        struct CustomHabitData {
            let name: String
            let emoji: String
            let colorHex: String
            let kind: HabitKind
            let unitLabel: String?
            let dailyTarget: Double?
            let schedule: HabitSchedule
        }
        
        // Define custom habits with curated emojis and colors that match their purpose
        let customHabitData = [
            CustomHabitData(name: "Practice Guitar", emoji: "🎸", colorHex: "#FF6B6B", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
            CustomHabitData(name: "Read Pages", emoji: "📚", colorHex: "#45B7D1", kind: .numeric, unitLabel: "pages", dailyTarget: 20.0, schedule: .daily),
            CustomHabitData(name: "Home Workouts", emoji: "💪", colorHex: "#4CAF50", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([1, 3, 5])) // Mon, Wed, Fri
        ]
        
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
            
            do {
                try await habitRepository.create(habit)
                createdHabits.append(habit)
            } catch {
                throw TestDataPopulationError("Failed to create custom habit '\(habitData.name)': \(error.localizedDescription)")
            }
        }
        
        return createdHabits
    }
    
    // MARK: - Sophisticated Pattern Generation
    
    /// Represents different life events that affect habit completion
    private enum LifeEvent {
        case vacation(intensity: Double)    // 0.0 = total break, 1.0 = perfect vacation habits
        case sickness(severity: Double)     // 0.0 = bedridden, 1.0 = mild cold
        case stressfulPeriod(impact: Double) // 0.0 = overwhelming, 1.0 = slightly busy
        case motivationBoost(boost: Double)  // 1.0 = normal, 2.0 = super motivated
        case perfectStreak(length: Int)      // Consecutive days of 100% completion
        case recovery(gradual: Bool)         // Post-disruption recovery period
    }
    
    /// Monthly performance baselines representing habit formation journey
    private struct MonthlyBaseline {
        let baselineRate: Double        // Core performance level
        let consistency: Double         // How stable the performance is (lower = more variation)
        let trendDirection: Double      // Positive = improving, negative = declining
        let description: String         // For debugging/understanding
    }
    
    /// Weekly variations within months
    private struct WeeklyPattern {
        let weekStartRate: Double       // Monday energy
        let midWeekRate: Double        // Wednesday productivity
        let weekendRate: Double        // Saturday/Sunday completion
        let fatiguePattern: Double     // How much performance drops through week
    }
    
    private func generateMonthlyPerformanceBaselines() -> [MonthlyBaseline] {
        return [
            // Month 1 (90-60 days ago): Enthusiastic start, then reality hits
            MonthlyBaseline(
                baselineRate: 0.72,
                consistency: 0.6,  // High variation - learning period
                trendDirection: -0.1,  // Slight decline as novelty wears off
                description: "Initial enthusiasm with reality check"
            ),
            
            // Month 2 (60-30 days ago): The struggle period, building discipline
            MonthlyBaseline(
                baselineRate: 0.58,
                consistency: 0.75, // More consistent, but lower overall
                trendDirection: 0.05,  // Gradual improvement
                description: "Discipline building phase"
            ),
            
            // Month 3 (30-0 days ago): Habit formation success, more stable
            MonthlyBaseline(
                baselineRate: 0.78,
                consistency: 0.85, // Much more consistent
                trendDirection: 0.08,  // Clear improvement trend
                description: "Habit formation mastery"
            )
        ]
    }
    
    private func generateWeeklyVariations(for dateRange: [Date], calendar: Calendar) -> [Date: WeeklyPattern] {
        var patterns: [Date: WeeklyPattern] = [:]
        
        for date in dateRange {
            let weekday = calendar.component(.weekday, from: date) // 1 = Sunday, 2 = Monday...
            
            // Create realistic weekly patterns
            let pattern = WeeklyPattern(
                weekStartRate: Double.random(in: 0.8...0.95),    // Strong Monday motivation
                midWeekRate: Double.random(in: 0.7...0.85),      // Steady midweek
                weekendRate: Double.random(in: 0.5...0.9),       // Variable weekends
                fatiguePattern: Double.random(in: 0.85...0.95)   // How much energy drops
            )
            
            patterns[date] = pattern
        }
        
        return patterns
    }
    
    private func generateLifeEvents(for dateRange: [Date], calendar: Calendar) -> [Date: LifeEvent] {
        var events: [Date: LifeEvent] = [:]
        let totalDays = dateRange.count
        
        // Add 2-3 zero completion days (life happens!)
        let zeroCompletionDays = Set((0..<3).compactMap { _ in
            dateRange.randomElement()
        })
        
        for date in zeroCompletionDays {
            events[date] = .sickness(severity: 0.0)
        }
        
        // Add vacation period (5-7 days, lower completion but not zero)
        if let vacationStart = dateRange.dropFirst(totalDays/3).dropLast(totalDays/3).randomElement() {
            for dayOffset in 0..<Int.random(in: 5...7) {
                if let vacationDay = calendar.date(byAdding: .day, value: dayOffset, to: vacationStart) {
                    events[vacationDay] = .vacation(intensity: Double.random(in: 0.2...0.5))
                }
            }
        }
        
        // Add motivation boost period (3-5 days of excellent performance)
        if let boostStart = dateRange.dropFirst(totalDays/2).randomElement() {
            for dayOffset in 0..<Int.random(in: 3...5) {
                if let boostDay = calendar.date(byAdding: .day, value: dayOffset, to: boostStart) {
                    events[boostDay] = .motivationBoost(boost: Double.random(in: 1.3...1.5))
                }
            }
        }
        
        // Add stressful period (4-6 days of reduced performance)
        if let stressStart = dateRange.dropFirst(totalDays/4).dropLast(totalDays/2).randomElement() {
            for dayOffset in 0..<Int.random(in: 4...6) {
                if let stressDay = calendar.date(byAdding: .day, value: dayOffset, to: stressStart) {
                    events[stressDay] = .stressfulPeriod(impact: Double.random(in: 0.3...0.6))
                }
            }
        }
        
        // Add perfect streak (7-10 days of 100% completion) 
        if let streakStart = dateRange.dropFirst(totalDays*2/3).randomElement() {
            let streakLength = Int.random(in: 7...10)
            for dayOffset in 0..<streakLength {
                if let streakDay = calendar.date(byAdding: .day, value: dayOffset, to: streakStart) {
                    events[streakDay] = .perfectStreak(length: streakLength)
                }
            }
        }
        
        return events
    }
    
    private func calculateDailyCompletionRate(
        date: Date,
        dayIndex: Int,
        monthlyBaselines: [MonthlyBaseline],
        weeklyVariations: [Date: WeeklyPattern],
        specialEvents: [Date: LifeEvent],
        calendar: Calendar
    ) -> Double {
        
        // Determine which month we're in (0 = oldest month, 2 = most recent)
        let monthIndex = min(2, dayIndex / 30)
        let baseline = monthlyBaselines[monthIndex]
        
        // Start with monthly baseline
        var completionRate = baseline.baselineRate
        
        // Apply trend (gradual improvement/decline over time)
        let progressInMonth = Double(dayIndex % 30) / 30.0
        completionRate += baseline.trendDirection * progressInMonth
        
        // Apply weekly pattern variations
        if let weeklyPattern = weeklyVariations[date] {
            let weekday = calendar.component(.weekday, from: date)
            let weekdayMultiplier: Double
            
            switch weekday {
            case 2, 3: // Monday, Tuesday - high energy
                weekdayMultiplier = weeklyPattern.weekStartRate
            case 4, 5: // Wednesday, Thursday - steady
                weekdayMultiplier = weeklyPattern.midWeekRate * weeklyPattern.fatiguePattern
            case 6, 7, 1: // Friday, Saturday, Sunday - variable
                weekdayMultiplier = weeklyPattern.weekendRate
            default:
                weekdayMultiplier = 0.75
            }
            
            completionRate *= weekdayMultiplier
        }
        
        // Apply special events (this can override everything else)
        if let event = specialEvents[date] {
            switch event {
            case .vacation(let intensity):
                completionRate = intensity
            case .sickness(let severity):
                completionRate = severity  // Can be 0.0 for complete zero days
            case .stressfulPeriod(let impact):
                completionRate *= impact
            case .motivationBoost(let boost):
                completionRate = min(1.0, completionRate * boost)
            case .perfectStreak(_):
                completionRate = 1.0  // Perfect completion
            case .recovery(let gradual):
                if gradual {
                    completionRate *= Double.random(in: 0.6...0.9)  // Gradual recovery
                } else {
                    completionRate *= Double.random(in: 0.4...0.7)  // Slower recovery
                }
            }
        }
        
        // Add natural daily variation based on consistency level
        let variationRange = (1.0 - baseline.consistency) * 0.3 // Up to 30% variation for low consistency
        let dailyVariation = Double.random(in: -variationRange...variationRange)
        completionRate += dailyVariation
        
        // Ensure completion rate stays within realistic bounds
        return max(0.0, min(1.0, completionRate))
    }
    
    private func generateHistoricalData(for habits: [Habit]) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate data for past 90 days (3 months) to create rich historical patterns
        let dateRange = Array((0..<90).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.reversed()) // Oldest to newest
        
        // Create sophisticated completion patterns with monthly and weekly variations
        var dailyCompletionRates: [Date: Double] = [:]
        
        // Define monthly performance trajectory - a journey of habit formation
        let monthlyBaselines = generateMonthlyPerformanceBaselines()
        
        // Generate weekly patterns within each month
        let weeklyVariations = generateWeeklyVariations(for: dateRange, calendar: calendar)
        
        // Add special events and life disruptions
        let specialEvents = generateLifeEvents(for: dateRange, calendar: calendar)
        
        for (dayIndex, date) in dateRange.enumerated() {
            let isToday = calendar.isDate(date, inSameDayAs: today)
            
            if isToday {
                // Today should have only 3 habits remaining (high completion ~80-90%)
                let activeHabitsCount = habits.filter { habit in
                    habitCompletionService.isScheduledDay(habit: habit, date: date)
                }.count
                let targetRemaining = 3
                let targetCompleted = max(0, activeHabitsCount - targetRemaining)
                dailyCompletionRates[date] = min(1.0, Double(targetCompleted) / Double(activeHabitsCount))
            } else {
                // Historical days: Apply sophisticated pattern generation
                let completionRate = calculateDailyCompletionRate(
                    date: date,
                    dayIndex: dayIndex,
                    monthlyBaselines: monthlyBaselines,
                    weeklyVariations: weeklyVariations,
                    specialEvents: specialEvents,
                    calendar: calendar
                )
                
                dailyCompletionRates[date] = completionRate
            }
        }
        
        // Apply daily patterns to habits
        for (dayIndex, date) in dateRange.enumerated() {
            guard let dailyCompletionRate = dailyCompletionRates[date] else { continue }
            
            // Progress tracking for 3-month generation (70-95% of total progress)
            let progressForDate = 0.7 + (Double(dayIndex) / Double(dateRange.count)) * 0.25
            let weekNumber = (dateRange.count - dayIndex - 1) / 7 + 1 // Count weeks backwards
            progressUpdate?("Creating 3-month history: Week \(weekNumber)...", progressForDate)
            
            // Get habits scheduled for this day
            let scheduledHabits = habits.filter { habit in
                habitCompletionService.isScheduledDay(habit: habit, date: date)
            }
            
            guard !scheduledHabits.isEmpty else { continue }
            
            // Determine how many habits to complete based on daily rate
            let targetCompletions = Int(round(Double(scheduledHabits.count) * dailyCompletionRate))
            
            // Randomly select which habits to complete (consistent with user's expectation)
            let shuffledHabits = scheduledHabits.shuffled()
            let habitsToComplete = Array(shuffledHabits.prefix(targetCompletions))
            
            // Create logs for selected habits
            for habit in habitsToComplete {
                let logValue: Double?
                
                switch habit.kind {
                case .binary:
                    logValue = 1.0 // Binary completion
                    
                case .numeric:
                    if let target = habit.dailyTarget {
                        // Meet or slightly exceed target (90-110% variation)
                        let variation = Double.random(in: 0.9...1.1)
                        logValue = target * variation
                    } else {
                        // Default numeric value for habits without targets
                        logValue = Double.random(in: 1.0...10.0)
                    }
                }
                
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: date,
                    value: logValue
                )
                
                do {
                    try await logHabitUseCase.execute(log)
                } catch {
                    // Log but continue - individual log failures shouldn't stop the process
                    print("Failed to create log for habit '\(habit.name)' on \(date): \(error)")
                }
            }
        }
    }
}
// swiftlint:enable type_body_length
#else
// Release build stub - never instantiated
public final class TestDataPopulationService: TestDataPopulationServiceProtocol {
    public var progressUpdate: ((String, Double) -> Void)?
    
    public init(
        debugService: DebugServiceProtocol,
        habitSuggestionsService: HabitSuggestionsService,
        createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase,
        createCustomCategoryUseCase: CreateCustomCategoryUseCase,
        logHabitUseCase: LogHabitUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        habitCompletionService: HabitCompletionServiceProtocol
    ) {}
    
    public func populateTestData() async throws {
        // No-op in release builds
    }
}
#endif