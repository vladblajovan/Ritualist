// Re-export DebugService protocol from RitualistCore
// Implementation must stay in app layer due to SwiftData model dependencies
import Foundation
import SwiftData
import RitualistCore
import FactoryKit

// Re-export protocol from RitualistCore
public typealias DebugServiceProtocol = RitualistCore.DebugServiceProtocol
public typealias DebugDatabaseStats = RitualistCore.DebugDatabaseStats

// Implementation remains in app layer due to SwiftData model dependencies
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
        // CRITICAL: Use Active* type aliases to work with current schema version
        try await MainActor.run {
            // 1. Delete all habit logs first (child entities)
            let habitLogs = try context.fetch(FetchDescriptor<ActiveHabitLogModel>())
            for log in habitLogs {
                context.delete(log)
            }

            // 2. Delete personality analysis data
            let personalityAnalysis = try context.fetch(FetchDescriptor<ActivePersonalityAnalysisModel>())
            for analysis in personalityAnalysis {
                context.delete(analysis)
            }

            // 3. Delete habits (references categories)
            let habits = try context.fetch(FetchDescriptor<ActiveHabitModel>())
            for habit in habits {
                context.delete(habit)
            }

            // 4. Delete categories
            let categories = try context.fetch(FetchDescriptor<ActiveHabitCategoryModel>())
            for category in categories {
                context.delete(category)
            }

            // 5. Delete user profiles
            let profiles = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
            for profile in profiles {
                context.delete(profile)
            }

            // 6. Delete onboarding state
            let onboardingStates = try context.fetch(FetchDescriptor<ActiveOnboardingStateModel>())
            for state in onboardingStates {
                context.delete(state)
            }

            // Save all changes
            try context.save()
        }

        // CRITICAL: Allow time for save to complete and caches to clear
        // SwiftData may have cached references to old schema versions
        try await Task.sleep(for: .milliseconds(100))
    }
    
    public func getDatabaseStats() async throws -> DebugDatabaseStats {
        let context = persistenceContainer.context

        // CRITICAL: Use Active* type aliases to work with current schema version
        return try await MainActor.run {
            let habitsCount = try context.fetchCount(FetchDescriptor<ActiveHabitModel>())
            let logsCount = try context.fetchCount(FetchDescriptor<ActiveHabitLogModel>())
            let categoriesCount = try context.fetchCount(FetchDescriptor<ActiveHabitCategoryModel>())
            let profilesCount = try context.fetchCount(FetchDescriptor<ActiveUserProfileModel>())

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
        DebugDatabaseStats(habitsCount: 0, logsCount: 0, categoriesCount: 0, profilesCount: 0)
    }
}
#endif
