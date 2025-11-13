//
//  PersonalityAnalysisRepositoryImpl.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import SwiftData

public final class PersonalityAnalysisRepositoryImpl: PersonalityAnalysisRepositoryProtocol {
    
    private let dataSource: PersonalityAnalysisDataSourceProtocol
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let logRepository: LogRepository
    private let suggestionsService: HabitSuggestionsService
    private let completionCalculator: ScheduleAwareCompletionCalculator
    private let getBatchLogs: GetBatchLogsUseCase
    
    public init(
        dataSource: PersonalityAnalysisDataSourceProtocol,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        logRepository: LogRepository,
        suggestionsService: HabitSuggestionsService,
        completionCalculator: ScheduleAwareCompletionCalculator = DefaultScheduleAwareCompletionCalculator(),
        getBatchLogs: GetBatchLogsUseCase
    ) {
        self.dataSource = dataSource
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.logRepository = logRepository
        self.suggestionsService = suggestionsService
        self.completionCalculator = completionCalculator
        self.getBatchLogs = getBatchLogs
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
        
        // Get all habit logs for the last 30 days using batch optimization
        let endDate = Date()
        let startDate = CalendarUtils.addDays(-30, to: endDate)
        
        // OPTIMIZATION: Use batch loading to avoid N+1 queries (was: N individual calls)
        let habitIds = activeHabits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: startDate, until: endDate)
        let allLogs = logsByHabitId.values.flatMap { $0 }
        
        // Calculate completion rates per habit using schedule-aware logic
        let completionRates = activeHabits.map { habit in
            completionCalculator.calculateCompletionRate(
                for: habit,
                logs: allLogs,
                startDate: startDate,
                endDate: endDate
            )
        }
        
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
    
    private func calculateConsecutiveTrackingDays(logs: [HabitLog]) -> Int {
        // Group logs by date using LOCAL timezone business logic
        let logsByDate = Dictionary(grouping: logs, by: {
            CalendarUtils.startOfDayLocal(for: $0.date)
        })

        let sortedDates = logsByDate.keys.sorted(by: >)

        var consecutiveDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: Date())

        for date in sortedDates {
            if CalendarUtils.areSameDayLocal(date, currentDate) {
                consecutiveDays += 1
                currentDate = CalendarUtils.addDays(-1, to: currentDate)
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

    public func getUserCustomCategories(for userId: UUID) async throws -> [HabitCategory] {
        try await categoryRepository.getCustomCategories()
    }
    
    public func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
        // Get all active habits for the user
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabits = allHabits.filter { $0.isActive }
        
        if activeHabits.isEmpty {
            return HabitCompletionStats(totalHabits: 0, completedHabits: 0, completionRate: 0.0)
        }
        
        // OPTIMIZATION: Use batch loading to avoid N+1 queries (was: N individual calls)
        let habitIds = activeHabits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: startDate, until: endDate)
        let allLogs = logsByHabitId.values.flatMap { $0 }
        
        // Use the schedule-aware completion calculator
        return completionCalculator.calculateCompletionStats(
            for: activeHabits,
            logs: allLogs,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    public func isPersonalityAnalysisEnabled(for userId: UUID) async throws -> Bool {
        if let preferences = try await getAnalysisPreferences(for: userId) {
            return preferences.isCurrentlyActive
        }
        return true // Default to enabled if no preferences exist
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
            throw PersonalityAnalysisError.dataEncodingFailed
        }
    }
}
