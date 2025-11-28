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
    private let logger: DebugLogger

    public init(
        modelContext: ModelContext,
        iCloudKeyValueService: iCloudKeyValueService,
        logger: DebugLogger = DebugLogger(subsystem: "com.vladblajovan.Ritualist", category: "iCloudData")
    ) {
        self.modelContext = modelContext
        self.iCloudKeyValueService = iCloudKeyValueService
        self.logger = logger
    }

    public func execute() async throws {
        // Delete all SwiftData records - CloudKit will automatically sync the deletions
        // This is GDPR Article 17 "Right to Erasure" compliance

        try modelContext.delete(model: ActiveHabitModel.self)
        try modelContext.delete(model: ActiveHabitLogModel.self)
        try modelContext.delete(model: ActiveHabitCategoryModel.self)
        try modelContext.delete(model: ActiveUserProfileModel.self)
        try modelContext.delete(model: ActiveOnboardingStateModel.self)
        try modelContext.delete(model: ActivePersonalityAnalysisModel.self)

        // Save the deletions - SwiftData will automatically sync to CloudKit
        try modelContext.save()

        // Clear sync metadata from UserDefaults
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastSyncDate)

        // Clear iCloud KV store onboarding flag so user sees onboarding on reinstall
        logger.log("🗑️ Clearing iCloud KV onboarding flags", level: .info, category: .system)
        iCloudKeyValueService.resetOnboardingFlag()
        iCloudKeyValueService.resetLocalOnboardingFlag()
        logger.log("✅ iCloud KV onboarding flags cleared", level: .info, category: .system)
    }
}
