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
    private let completionCalculator: ScheduleAwareCompletionCalculator
    private let getBatchLogs: GetBatchLogsUseCase
    private let getHabitAnalysisInput: GetHabitAnalysisInputUseCase
    private let thresholdValidator: DataThresholdValidator
    private let preferencesDataSource: PersonalityPreferencesDataSource

    public init(
        dataSource: PersonalityAnalysisDataSourceProtocol,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        completionCalculator: ScheduleAwareCompletionCalculator = DefaultScheduleAwareCompletionCalculator(),
        getBatchLogs: GetBatchLogsUseCase,
        getHabitAnalysisInput: GetHabitAnalysisInputUseCase,
        thresholdValidator: DataThresholdValidator,
        preferencesDataSource: PersonalityPreferencesDataSource
    ) {
        self.dataSource = dataSource
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.completionCalculator = completionCalculator
        self.getBatchLogs = getBatchLogs
        self.getHabitAnalysisInput = getHabitAnalysisInput
        self.thresholdValidator = thresholdValidator
        self.preferencesDataSource = preferencesDataSource
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
        return try await thresholdValidator.validateEligibility(for: userId)
    }

    public func getThresholdProgress(for userId: UUID) async throws -> [ThresholdRequirement] {
        return try await thresholdValidator.getThresholdProgress(for: userId)
    }
    
    public func getHabitAnalysisInput(for userId: UUID) async throws -> HabitAnalysisInput {
        return try await getHabitAnalysisInput.execute(for: userId)
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
        return try await preferencesDataSource.getPreferences(for: userId)
    }

    public func saveAnalysisPreferences(_ preferences: PersonalityAnalysisPreferences) async throws {
        try await preferencesDataSource.savePreferences(preferences)
    }
}
