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

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        UserDefaults.standard.removeObject(forKey: "com.ritualist.lastSyncDate")
    }
}
