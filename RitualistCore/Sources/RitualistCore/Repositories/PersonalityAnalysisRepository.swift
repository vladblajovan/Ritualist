//
//  PersonalityAnalysisRepository.swift
//  RitualistCore
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Repository protocol for personality analysis data operations
public protocol PersonalityAnalysisRepositoryProtocol {
    
    // MARK: - Personality Profile Management
    
    /// Retrieve the latest personality profile for a user
    func getPersonalityProfile(for userId: UUID) async throws -> PersonalityProfile?
    
    /// Save a new personality profile
    func savePersonalityProfile(_ profile: PersonalityProfile) async throws
    
    /// Get personality analysis history for a user
    func getPersonalityHistory(for userId: UUID) async throws -> [PersonalityProfile]
    
    /// Delete a specific personality profile
    func deletePersonalityProfile(id: UUID) async throws
    
    /// Delete all personality profiles for a user
    func deleteAllPersonalityProfiles(for userId: UUID) async throws
    
    // MARK: - Analysis Eligibility and Validation
    
    /// Check if user has enough data for personality analysis
    func validateAnalysisEligibility(for userId: UUID) async throws -> AnalysisEligibility
    
    /// Get current progress toward meeting analysis thresholds
    func getThresholdProgress(for userId: UUID) async throws -> [ThresholdRequirement]
    
    /// Get all data needed for habit analysis
    func getHabitAnalysisInput(for userId: UUID) async throws -> HabitAnalysisInput
    
    // MARK: - User Data Retrieval for Analysis
    
    /// Get all habits for a user
    func getUserHabits(for userId: UUID) async throws -> [Habit]
    
    /// Get habit logs for a user within a date range
    func getUserHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
    
    /// Get custom categories created by a user
    func getUserCustomCategories(for userId: UUID) async throws -> [Category]
    
    /// Get comprehensive habit completion statistics
    func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats
    
    // MARK: - Analysis Settings
    
    /// Check if personality analysis is enabled for a user
    func isPersonalityAnalysisEnabled(for userId: UUID) async throws -> Bool
    
    /// Get user's analysis preferences
    func getAnalysisPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences?
    
    /// Save user's analysis preferences
    func saveAnalysisPreferences(_ preferences: PersonalityAnalysisPreferences) async throws
}