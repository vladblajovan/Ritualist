//
//  PersonalityAnalysisRepositoryImpl.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import SwiftData

public final class PersonalityAnalysisRepositoryImpl: PersonalityAnalysisRepositoryProtocol {
    
    private let dataSource: PersonalityAnalysisDataSource
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let logRepository: LogRepository
    private let suggestionsService: HabitSuggestionsService
    
    public init(
        dataSource: PersonalityAnalysisDataSource,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        logRepository: LogRepository,
        suggestionsService: HabitSuggestionsService
    ) {
        self.dataSource = dataSource
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.logRepository = logRepository
        self.suggestionsService = suggestionsService
    }
    
    public func getPersonalityProfile(for userId: UUID) async throws -> PersonalityProfile? {
        try await dataSource.getLatestProfile(for: userId)
    }
    
    public func savePersonalityProfile(_ profile: PersonalityProfile) async throws {
        try await dataSource.saveProfile(profile)
    }
    
    public func getPersonalityHistory(for userId: UUID) async throws -> [PersonalityProfile] {
        try await dataSource.getProfileHistory(for: userId)
    }
    
    public func deletePersonalityProfile(id: UUID) async throws {
        try await dataSource.deleteProfile(profileId: id.uuidString)
    }
    
    public func deleteAllPersonalityProfiles(for userId: UUID) async throws {
        try await dataSource.deleteAllProfiles(for: userId)
    }
    
    public func validateAnalysisEligibility(for userId: UUID) async throws -> AnalysisEligibility {
        let input = try await getHabitAnalysisInput(for: userId)
        return validateEligibilityFromInput(input)
    }
    
    public func getThresholdProgress(for userId: UUID) async throws -> [ThresholdRequirement] {
        let input = try await getHabitAnalysisInput(for: userId)
        return buildThresholdRequirements(from: input)
    }
    
    public func getHabitAnalysisInput(for userId: UUID) async throws -> HabitAnalysisInput {
        // Get all active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabits = allHabits.filter { $0.isActive }
        
        // Get all habit logs for the last 30 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        var allLogs: [HabitLog] = []
        
        // Get logs for each active habit
        for habit in activeHabits {
            let habitLogs = try await logRepository.logs(for: habit.id)
            // Filter logs to the date range
            let filteredLogs = habitLogs.filter { log in
                log.date >= startDate && log.date <= endDate
            }
            allLogs.append(contentsOf: filteredLogs)
        }
        
        // Calculate completion rates per habit
        let completionRates = calculateCompletionRates(habits: activeHabits, logs: allLogs)
        
        // Get custom habits (non-suggested habits)
        let customHabits = activeHabits.filter { $0.suggestionId == nil }
        
        // Get all categories
        let allCategories = try await categoryRepository.getAllCategories()
        let customCategories = try await categoryRepository.getCustomCategories()
        
        // Get habit categories (categories that have active habits)
        let habitCategoryIds = Set(activeHabits.map { $0.categoryId })
        let habitCategories = allCategories.filter { habitCategoryIds.contains($0.id) }
        
        // Get selected suggestions (habits that came from suggestions)
        let selectedSuggestions = try await getSelectedSuggestions(from: activeHabits)
        
        // Calculate tracking consistency
        let trackingDays = calculateConsecutiveTrackingDays(logs: allLogs)
        
        // Calculate total data points for analysis confidence
        // Now includes individual habit analysis (each active habit with completion rate = 1 data point)
        let individualHabitAnalysis = activeHabits.count
        let totalDataPoints = allLogs.count + customHabits.count + customCategories.count + individualHabitAnalysis
        
        return HabitAnalysisInput(
            activeHabits: activeHabits,
            completionRates: completionRates,
            customHabits: customHabits,
            customCategories: customCategories,
            habitCategories: habitCategories,
            selectedSuggestions: selectedSuggestions,
            trackingDays: trackingDays,
            analysisTimeRange: 30,
            totalDataPoints: totalDataPoints
        )
    }
    
    // MARK: - Private Helpers
    
    private func calculateCompletionRates(habits: [Habit], logs: [HabitLog]) -> [Double] {
        let logsByHabit = Dictionary(grouping: logs, by: { $0.habitID })
        
        return habits.map { habit in
            let habitLogs = logsByHabit[habit.id] ?? []
            let completedLogs = habitLogs.filter { log in
                switch habit.kind {
                case .binary:
                    return true // For binary habits, existence of log means completion
                case .numeric:
                    // For numeric habits, check if value meets target (if target exists)
                    if let target = habit.dailyTarget, let value = log.value {
                        return value >= target
                    } else {
                        return log.value != nil
                    }
                }
            }
            
            guard !habitLogs.isEmpty else { return 0.0 }
            return Double(completedLogs.count) / Double(habitLogs.count)
        }
    }
    
    private func calculateConsecutiveTrackingDays(logs: [HabitLog]) -> Int {
        // Group logs by date
        let logsByDate = Dictionary(grouping: logs, by: { 
            Calendar.current.startOfDay(for: $0.date) 
        })
        
        let sortedDates = logsByDate.keys.sorted(by: >)
        
        var consecutiveDays = 0
        let calendar = Calendar.current
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                consecutiveDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if date < currentDate {
                // Gap in tracking, stop counting
                break
            }
        }
        
        return consecutiveDays
    }
    
    private func getSelectedSuggestions(from habits: [Habit]) async throws -> [HabitSuggestion] {
        var selectedSuggestions: [HabitSuggestion] = []
        
        // Find habits that were created from suggestions (have a suggestionId)
        let habitsSuggestionsIds = habits.compactMap { $0.suggestionId }
        
        // Look up the original suggestions by ID
        for suggestionId in habitsSuggestionsIds {
            if let suggestion = suggestionsService.getSuggestion(by: suggestionId) {
                selectedSuggestions.append(suggestion)
            }
        }
        
        return selectedSuggestions
    }
    
    /// Check if a habit is expected to be performed on a given date based on its schedule
    private func isHabitExpectedOnDate(habit: Habit, date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch habit.schedule {
        case .daily:
            return true
            
        case .daysOfWeek(let days):
            // Convert Calendar weekday (Sunday=1) to HabitSchedule format (Monday=1)
            let habitWeekday: Int
            if weekday == 1 { // Sunday
                habitWeekday = 7
            } else { // Monday=2 -> 1, Tuesday=3 -> 2, etc.
                habitWeekday = weekday - 1
            }
            return days.contains(habitWeekday)
            
        case .timesPerWeek(_):
            // For times per week, we consider the habit expected every day
            // The actual completion rate calculation will handle the flexible nature
            return true
        }
    }
    
    private func validateEligibilityFromInput(_ input: HabitAnalysisInput) -> AnalysisEligibility {
        let requirements = buildThresholdRequirements(from: input)
        let unmetRequirements = requirements.filter { !$0.isMet }
        
        if unmetRequirements.isEmpty {
            return AnalysisEligibility(
                isEligible: true,
                missingRequirements: [],
                overallProgress: 1.0,
                estimatedDaysToEligibility: nil
            )
        } else {
            return AnalysisEligibility(
                isEligible: false,
                missingRequirements: unmetRequirements,
                overallProgress: 0.5,
                estimatedDaysToEligibility: calculateEstimatedDays(from: unmetRequirements)
            )
        }
    }
    
    private func buildThresholdRequirements(from input: HabitAnalysisInput) -> [ThresholdRequirement] {
        var requirements: [ThresholdRequirement] = []
        
        // Active habits requirement
        requirements.append(ThresholdRequirement(
            name: "Active Habits",
            description: "Track at least 5 active habits consistently",
            currentValue: input.activeHabits.count,
            requiredValue: 5,
            category: .habits
        ))
        
        // Tracking consistency requirement
        requirements.append(ThresholdRequirement(
            name: "Consistent Tracking",
            description: "Log habits for at least 7 consecutive days",
            currentValue: input.trackingDays,
            requiredValue: 7,
            category: .tracking
        ))
        
        // Custom categories requirement
        requirements.append(ThresholdRequirement(
            name: "Custom Categories",
            description: "Create at least 3 custom habit categories",
            currentValue: input.customCategories.count,
            requiredValue: 3,
            category: .customization
        ))
        
        // Custom habits requirement
        requirements.append(ThresholdRequirement(
            name: "Custom Habits",
            description: "Create at least 3 custom habits",
            currentValue: input.customHabits.count,
            requiredValue: 3,
            category: .customization
        ))
        
        // Completion rate requirement
        let avgCompletionRate = input.completionRates.reduce(0.0, +) / Double(max(input.completionRates.count, 1))
        let completionRatePercent = Int(avgCompletionRate * 100)
        
        requirements.append(ThresholdRequirement(
            name: "Habit Completion Rate",
            description: "Maintain at least 30% completion rate across all habits",
            currentValue: completionRatePercent,
            requiredValue: 30,
            category: .tracking
        ))
        
        // Habit diversity requirement
        requirements.append(ThresholdRequirement(
            name: "Habit Diversity",
            description: "Track habits across at least 3 different categories",
            currentValue: input.habitCategories.count,
            requiredValue: 3,
            category: .diversity
        ))
        
        return requirements
    }
    
    private func calculateEstimatedDays(from unmetRequirements: [ThresholdRequirement]) -> Int? {
        var maxDaysNeeded = 0
        
        for requirement in unmetRequirements {
            switch requirement.category {
            case .tracking:
                let daysNeeded = requirement.requiredValue - requirement.currentValue
                maxDaysNeeded = max(maxDaysNeeded, max(0, daysNeeded))
            case .habits, .customization:
                maxDaysNeeded = max(maxDaysNeeded, 1)
            case .diversity:
                maxDaysNeeded = max(maxDaysNeeded, 3)
            }
        }
        
        return maxDaysNeeded > 0 ? maxDaysNeeded : nil
    }
    
    // MARK: - Additional Protocol Methods
    
    public func getUserHabits(for userId: UUID) async throws -> [Habit] {
        let allHabits = try await habitRepository.fetchAllHabits()
        return allHabits.filter { $0.isActive }
    }
    
    public func getUserHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        let activeHabits = try await getUserHabits(for: userId)
        var allLogs: [HabitLog] = []
        
        for habit in activeHabits {
            let habitLogs = try await logRepository.logs(for: habit.id)
            let filteredLogs = habitLogs.filter { log in
                log.date >= startDate && log.date <= endDate
            }
            allLogs.append(contentsOf: filteredLogs)
        }
        
        return allLogs
    }
    
    public func getUserCustomCategories(for userId: UUID) async throws -> [Category] {
        try await categoryRepository.getCustomCategories()
    }
    
    public func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
        // Get all active habits for the user
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabits = allHabits.filter { $0.isActive }
        
        // Calculate completion statistics
        let totalHabits = activeHabits.count
        
        if totalHabits == 0 {
            return HabitCompletionStats(totalHabits: 0, completedHabits: 0, completionRate: 0.0)
        }
        
        // Calculate completion for each habit in the date range
        var completedHabits = 0
        var totalExpectedEntries = 0
        var totalCompletedEntries = 0
        
        let calendar = Calendar.current
        
        for habit in activeHabits {
            // Get logs for this specific habit
            let habitLogs = try await logRepository.logs(for: habit.id)
            
            // Filter logs to the date range
            let logsInRange = habitLogs.filter { log in
                let logDate = calendar.startOfDay(for: log.date)
                let rangeStart = calendar.startOfDay(for: startDate)
                let rangeEnd = calendar.startOfDay(for: endDate)
                return logDate >= rangeStart && logDate <= rangeEnd
            }
            
            let logsByDate = Dictionary(grouping: logsInRange, by: { calendar.startOfDay(for: $0.date) })
            
            var habitCompletedDays = 0
            var habitExpectedDays = 0
            
            // Check each day in the range to see if habit was expected and completed
            var currentDate = calendar.startOfDay(for: startDate)
            let endOfRange = calendar.startOfDay(for: endDate)
            
            while currentDate <= endOfRange {
                defer {
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
                
                // Skip if habit wasn't active yet
                if currentDate < calendar.startOfDay(for: habit.startDate) {
                    continue
                }
                
                // Skip if habit ended before this date
                if let endDate = habit.endDate, currentDate > calendar.startOfDay(for: endDate) {
                    continue
                }
                
                // Check if habit was expected on this day based on schedule
                let isExpected = isHabitExpectedOnDate(habit: habit, date: currentDate)
                if !isExpected {
                    continue
                }
                
                habitExpectedDays += 1
                
                // Check if habit was completed on this day
                if let dayLogs = logsByDate[currentDate] {
                    let isCompleted = dayLogs.contains(where: { log in
                        switch habit.kind {
                        case .binary:
                            // For binary habits, any non-nil value means completed
                            return log.value != nil && log.value! > 0
                        case .numeric:
                            // For numeric habits, check if value meets the daily target
                            return (log.value ?? 0) >= (habit.dailyTarget ?? 1)
                        }
                    })
                    
                    if isCompleted {
                        habitCompletedDays += 1
                    }
                }
            }
            
            totalExpectedEntries += habitExpectedDays
            totalCompletedEntries += habitCompletedDays
            
            // Consider a habit "completed" if it has >50% completion rate in the period
            if habitExpectedDays > 0 && Double(habitCompletedDays) / Double(habitExpectedDays) > 0.5 {
                completedHabits += 1
            }
        }
        
        // Calculate overall completion rate
        let completionRate = totalExpectedEntries > 0 ? Double(totalCompletedEntries) / Double(totalExpectedEntries) : 0.0
        
        return HabitCompletionStats(
            totalHabits: totalHabits,
            completedHabits: completedHabits,
            completionRate: completionRate
        )
    }
    
    public func isPersonalityAnalysisEnabled(for userId: UUID) async throws -> Bool {
        true // Default to enabled
    }
    
    public func getAnalysisPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences? {
        let key = "personality_preferences_main_user"
        
        if let data = UserDefaults.standard.data(forKey: key),
           let preferences = try? JSONDecoder().decode(PersonalityAnalysisPreferences.self, from: data) {
            return preferences
        }
        
        // Migration logic for old userId-based keys
        let oldKey = "personality_preferences_\(userId.uuidString)"
        if let oldData = UserDefaults.standard.data(forKey: oldKey),
           let oldPreferences = try? JSONDecoder().decode(PersonalityAnalysisPreferences.self, from: oldData) {
            UserDefaults.standard.set(oldData, forKey: key)
            UserDefaults.standard.removeObject(forKey: oldKey)
            return oldPreferences
        }
        
        return nil
    }
    
    public func saveAnalysisPreferences(_ preferences: PersonalityAnalysisPreferences) async throws {
        let key = "personality_preferences_main_user"
        
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            throw NSError(domain: "PersonalityRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode preferences"])
        }
    }
}
