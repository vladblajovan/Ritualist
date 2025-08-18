//
//  DebugService.swift
//  Ritualist
//
//  Created by Claude on 18.08.2025.
//

import Foundation
import SwiftData
import FactoryKit

/// Service for debug operations like database clearing
/// Only available in debug builds
public protocol DebugServiceProtocol {
    /// Clear all data from the database
    func clearDatabase() async throws
    
    /// Get database statistics
    func getDatabaseStats() async throws -> DebugDatabaseStats
}

public struct DebugDatabaseStats {
    public let habitsCount: Int
    public let logsCount: Int
    public let categoriesCount: Int
    public let profilesCount: Int
    
    public init(habitsCount: Int, logsCount: Int, categoriesCount: Int, profilesCount: Int) {
        self.habitsCount = habitsCount
        self.logsCount = logsCount
        self.categoriesCount = categoriesCount
        self.profilesCount = profilesCount
    }
}

#if DEBUG
public final class DebugService: DebugServiceProtocol {
    private let persistenceContainer: PersistenceContainer
    
    public init(persistenceContainer: PersistenceContainer) {
        self.persistenceContainer = persistenceContainer
    }
    
    public func clearDatabase() async throws {
        let context = persistenceContainer.context
        
        // Delete all data by fetching and deleting individual records
        // This respects SwiftData relationship constraints properly
        try await MainActor.run {
            // 1. Delete all habit logs first (child entities)
            let habitLogs = try context.fetch(FetchDescriptor<HabitLogModel>())
            for log in habitLogs {
                context.delete(log)
            }
            
            // 2. Delete personality analysis data
            let personalityAnalysis = try context.fetch(FetchDescriptor<PersonalityAnalysisModel>())
            for analysis in personalityAnalysis {
                context.delete(analysis)
            }
            
            // 3. Delete habits (references categories)
            let habits = try context.fetch(FetchDescriptor<HabitModel>())
            for habit in habits {
                context.delete(habit)
            }
            
            // 4. Delete categories
            let categories = try context.fetch(FetchDescriptor<HabitCategoryModel>())
            for category in categories {
                context.delete(category)
            }
            
            // 5. Delete user profiles
            let profiles = try context.fetch(FetchDescriptor<UserProfileModel>())
            for profile in profiles {
                context.delete(profile)
            }
            
            // 6. Delete onboarding state
            let onboardingStates = try context.fetch(FetchDescriptor<OnboardingStateModel>())
            for state in onboardingStates {
                context.delete(state)
            }
            
            // Save all changes
            try context.save()
        }
    }
    
    public func getDatabaseStats() async throws -> DebugDatabaseStats {
        let context = persistenceContainer.context
        
        return try await MainActor.run {
            let habitsCount = try context.fetchCount(FetchDescriptor<HabitModel>())
            let logsCount = try context.fetchCount(FetchDescriptor<HabitLogModel>())
            let categoriesCount = try context.fetchCount(FetchDescriptor<HabitCategoryModel>())
            let profilesCount = try context.fetchCount(FetchDescriptor<UserProfileModel>())
            
            return DebugDatabaseStats(
                habitsCount: habitsCount,
                logsCount: logsCount,
                categoriesCount: categoriesCount,
                profilesCount: profilesCount
            )
        }
    }
}
#else
// Release build stub - never instantiated
public final class DebugService: DebugServiceProtocol {
    public init(persistenceContainer: PersistenceContainer) {}
    
    public func clearDatabase() async throws {
        // No-op in release builds
    }
    
    public func getDatabaseStats() async throws -> DebugDatabaseStats {
        return DebugDatabaseStats(habitsCount: 0, logsCount: 0, categoriesCount: 0, profilesCount: 0)
    }
}
#endif