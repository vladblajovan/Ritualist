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
    
    public init(
        dataSource: PersonalityAnalysisDataSource,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        logRepository: LogRepository
    ) {
        self.dataSource = dataSource
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.logRepository = logRepository
    }
    
    public func getPersonalityProfile(for userId: UUID) async throws -> PersonalityProfile? {
        return try await dataSource.getLatestProfile(for: userId)
    }
    
    public func savePersonalityProfile(_ profile: PersonalityProfile) async throws {
        try await dataSource.saveProfile(profile)
    }
    
    public func getPersonalityHistory(for userId: UUID) async throws -> [PersonalityProfile] {
        return try await dataSource.getProfileHistory(for: userId)
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
        let totalDataPoints = allLogs.count + customHabits.count + customCategories.count
        
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
        
        // This would need to be implemented based on how suggestions are stored
        // For now, return empty array - this would need integration with suggestion data
        
        return selectedSuggestions
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
        return try await categoryRepository.getCustomCategories()
    }
    
    public func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
        // Stub implementation
        return HabitCompletionStats(totalHabits: 0, completedHabits: 0, completionRate: 0.0)
    }
    
    public func isPersonalityAnalysisEnabled(for userId: UUID) async throws -> Bool {
        return true // Default to enabled
    }
    
    public func setPersonalityAnalysisEnabled(_ enabled: Bool, for userId: UUID) async throws {
        // Stub implementation
    }
    
    public func getAnalysisPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences? {
        return nil // No preferences saved
    }
    
    public func saveAnalysisPreferences(_ preferences: PersonalityAnalysisPreferences) async throws {
        // Stub implementation
    }
}
