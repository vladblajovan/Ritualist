//
//  DefaultDeleteiCloudDataUseCase.swift
//  RitualistCore
//
//  Default implementation for deleting iCloud data
//

import Foundation
import SwiftData

public final class DefaultDeleteiCloudDataUseCase: DeleteiCloudDataUseCase {
    private let modelContext: ModelContext
    private let iCloudKeyValueService: iCloudKeyValueService
    private let userDefaults: UserDefaultsService
    private let logger: DebugLogger

    public init(
        modelContext: ModelContext,
        iCloudKeyValueService: iCloudKeyValueService,
        userDefaults: UserDefaultsService = DefaultUserDefaultsService(),
        logger: DebugLogger = DebugLogger(subsystem: "com.vladblajovan.Ritualist", category: "iCloudData")
    ) {
        self.modelContext = modelContext
        self.iCloudKeyValueService = iCloudKeyValueService
        self.userDefaults = userDefaults
        self.logger = logger
    }

    public func execute() async throws {
        // Delete all SwiftData records locally
        // CloudKit will automatically sync the deletions when available
        // This is GDPR Article 17 "Right to Erasure" compliance

        logger.log("🗑️ Starting data deletion...", level: .info, category: .system)

        // CRITICAL: Use fetch-and-delete instead of batch delete (modelContext.delete(model:))
        // Batch delete doesn't work reliably across multiple stores (CloudKit + Local).
        // Fetch-and-delete properly handles models in different stores.
        try await MainActor.run {
            // 1. Delete all habit logs first (child entities)
            let habitLogs = try modelContext.fetch(FetchDescriptor<ActiveHabitLogModel>())
            for log in habitLogs {
                modelContext.delete(log)
            }
            logger.log("🗑️ Deleted \(habitLogs.count) habit logs", level: .debug, category: .system)

            // 2. Delete habits (references categories)
            let habits = try modelContext.fetch(FetchDescriptor<ActiveHabitModel>())
            for habit in habits {
                modelContext.delete(habit)
            }
            logger.log("🗑️ Deleted \(habits.count) habits", level: .debug, category: .system)

            // 3. Delete categories
            let categories = try modelContext.fetch(FetchDescriptor<ActiveHabitCategoryModel>())
            for category in categories {
                modelContext.delete(category)
            }
            logger.log("🗑️ Deleted \(categories.count) categories", level: .debug, category: .system)

            // 4. Delete user profiles
            let profiles = try modelContext.fetch(FetchDescriptor<ActiveUserProfileModel>())
            for profile in profiles {
                modelContext.delete(profile)
            }
            logger.log("🗑️ Deleted \(profiles.count) user profiles", level: .debug, category: .system)

            // 5. Delete onboarding states
            let onboardingStates = try modelContext.fetch(FetchDescriptor<ActiveOnboardingStateModel>())
            for state in onboardingStates {
                modelContext.delete(state)
            }
            logger.log("🗑️ Deleted \(onboardingStates.count) onboarding states", level: .debug, category: .system)

            // 6. Delete personality analyses (in Local store, NOT CloudKit store)
            let personalityAnalyses = try modelContext.fetch(FetchDescriptor<ActivePersonalityAnalysisModel>())
            for analysis in personalityAnalyses {
                modelContext.delete(analysis)
            }
            logger.log("🗑️ Deleted \(personalityAnalyses.count) personality analyses", level: .debug, category: .system)

            // Save all deletions
            try modelContext.save()
        }
        logger.log("✅ All data deleted and saved", level: .info, category: .system)

        // Clear sync metadata from UserDefaults
        userDefaults.removeObject(forKey: UserDefaultsKeys.lastSyncDate)

        // Clear category seeding flag so categories are re-seeded on next launch
        userDefaults.removeObject(forKey: UserDefaultsKeys.categorySeedingCompleted)
        logger.log("🗑️ Cleared category seeding flag", level: .info, category: .system)

        // Clear iCloud KV store onboarding flag so user sees onboarding on reinstall
        logger.log("🗑️ Clearing iCloud KV onboarding flags", level: .info, category: .system)
        iCloudKeyValueService.resetOnboardingFlag()
        iCloudKeyValueService.resetLocalOnboardingFlag()
        logger.log("✅ iCloud KV onboarding flags cleared", level: .info, category: .system)

        logger.log("✅ Data deletion completed successfully", level: .info, category: .system)
    }
}
