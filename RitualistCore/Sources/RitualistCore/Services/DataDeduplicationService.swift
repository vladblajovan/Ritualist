//
//  DataDeduplicationService.swift
//  RitualistCore
//
//  Created by Claude on 26.11.2025.
//
//  Service to deduplicate records after CloudKit sync.
//
//  CloudKit + SwiftData sync can create duplicate records when:
//  1. @Attribute(.unique) is not available (CloudKit doesn't support it)
//  2. Multiple devices sync the same logical record
//  3. Network issues cause retry logic to insert multiple copies
//
//  This service finds records with duplicate IDs and merges them,
//  keeping one copy and deleting the extras.
//

import Foundation
import SwiftData

// MARK: - Protocol

/// Protocol for data deduplication operations
/// Handles cleanup of duplicate records that can occur during CloudKit sync
public protocol DataDeduplicationServiceProtocol: Sendable {
    /// Deduplicate all model types and return summary of changes
    func deduplicateAll() async throws -> DeduplicationResult

    /// Deduplicate habits only
    func deduplicateHabits() async throws -> Int

    /// Deduplicate categories only
    func deduplicateCategories() async throws -> Int

    /// Deduplicate habit logs only
    func deduplicateHabitLogs() async throws -> Int

    /// Deduplicate user profiles only
    func deduplicateProfiles() async throws -> Int
}

// MARK: - Result Type

/// Summary of deduplication operations
public struct DeduplicationResult: Sendable {
    public let habitsRemoved: Int
    public let categoriesRemoved: Int
    public let habitLogsRemoved: Int
    public let profilesRemoved: Int
    /// Total number of items that were in the database to check
    /// Used to determine if there was any data (0 = fresh install, data hasn't synced yet)
    public let totalItemsChecked: Int

    public var totalRemoved: Int {
        habitsRemoved + categoriesRemoved + habitLogsRemoved + profilesRemoved
    }

    public var hadDuplicates: Bool {
        totalRemoved > 0
    }

    /// Returns true if there was data in the database to check
    /// Used to determine whether to throttle subsequent deduplication runs
    public var hadDataToCheck: Bool {
        totalItemsChecked > 0
    }

    public init(habitsRemoved: Int, categoriesRemoved: Int, habitLogsRemoved: Int, profilesRemoved: Int = 0, totalItemsChecked: Int = 0) {
        self.habitsRemoved = habitsRemoved
        self.categoriesRemoved = categoriesRemoved
        self.habitLogsRemoved = habitLogsRemoved
        self.profilesRemoved = profilesRemoved
        self.totalItemsChecked = totalItemsChecked
    }
}

// MARK: - Implementation

/// Service that deduplicates records after CloudKit sync
/// Uses @ModelActor for background thread database operations
@ModelActor
public actor DataDeduplicationService: DataDeduplicationServiceProtocol {

    // Inline logger (cannot inject into @ModelActor - SwiftData limitation)
    private let logger = DebugLogger(subsystem: "com.ritualist.app", category: "deduplication")

    // MARK: - Public Methods

    public func deduplicateAll() async throws -> DeduplicationResult {
        logger.log("Starting full deduplication", level: .info, category: .dataIntegrity)

        // First, count total items in database to determine if there's data to check
        // This is used by callers to decide whether to throttle subsequent runs
        // Count ALL entity types to accurately reflect database state
        let habitsDescriptor = FetchDescriptor<ActiveHabitModel>()
        let categoriesDescriptor = FetchDescriptor<ActiveHabitCategoryModel>()
        let logsDescriptor = FetchDescriptor<ActiveHabitLogModel>()
        let profilesDescriptor = FetchDescriptor<ActiveUserProfileModel>()

        // Count entities - if any count fails, log warning but continue with 0
        // This is defensive: fetchCount should not fail on valid descriptors,
        // but if it does, we prefer to continue deduplication rather than abort
        let totalItems: Int
        do {
            let totalHabits = try modelContext.fetchCount(habitsDescriptor)
            let totalCategories = try modelContext.fetchCount(categoriesDescriptor)
            let totalLogs = try modelContext.fetchCount(logsDescriptor)
            let totalProfiles = try modelContext.fetchCount(profilesDescriptor)
            totalItems = totalHabits + totalCategories + totalLogs + totalProfiles
        } catch {
            // Log the error but don't abort - deduplication itself may still succeed
            logger.log(
                "⚠️ Failed to count entities for deduplication metrics",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            // Use 0 as fallback - hadDataToCheck will be false, which is conservative
            // (will cause continued dedup attempts rather than premature stop)
            totalItems = 0
        }

        let habits = try await deduplicateHabits()
        let categories = try await deduplicateCategories()
        let logs = try await deduplicateHabitLogs()
        let profiles = try await deduplicateProfiles()

        let result = DeduplicationResult(
            habitsRemoved: habits,
            categoriesRemoved: categories,
            habitLogsRemoved: logs,
            profilesRemoved: profiles,
            totalItemsChecked: totalItems
        )

        if result.hadDuplicates {
            logger.log(
                "Deduplication complete",
                level: .info,
                category: .dataIntegrity,
                metadata: [
                    "habits_removed": habits,
                    "categories_removed": categories,
                    "logs_removed": logs,
                    "profiles_removed": profiles,
                    "total_items_checked": totalItems
                ]
            )
        } else {
            logger.log(
                "Deduplication complete - no duplicates found",
                level: .debug,
                category: .dataIntegrity,
                metadata: ["total_items_checked": totalItems]
            )
        }

        return result
    }

    public func deduplicateHabits() async throws -> Int {
        do {
            // Fetch all habits
            let descriptor = FetchDescriptor<ActiveHabitModel>()
            let allHabits = try modelContext.fetch(descriptor)

            // Group by NAME to find duplicates (CloudKit creates new UUIDs for synced records)
            // This catches habits that are logically the same but have different UUIDs
            let grouped = Dictionary(grouping: allHabits) { $0.name }

            var removedCount = 0

            for (habitName, duplicates) in grouped where duplicates.count > 1 {
                logger.log(
                    "Found duplicate habits",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["name": habitName, "count": duplicates.count]
                )

                // Keep the one with the most logs, or most recent lastCompletedDate
                let sorted = duplicates.sorted { habit1, habit2 in
                    // Primary: keep the one with more logs (more data)
                    let logs1 = habit1.logs?.count ?? 0
                    let logs2 = habit2.logs?.count ?? 0
                    if logs1 != logs2 {
                        return logs1 > logs2
                    }

                    // Secondary: keep the one with more recent lastCompletedDate
                    let date1 = habit1.lastCompletedDate ?? Date.distantPast
                    let date2 = habit2.lastCompletedDate ?? Date.distantPast
                    return date1 > date2
                }

                // Keep the first (best) one, delete the rest
                let toKeep = sorted[0]
                let toDelete = sorted.dropFirst()

                for duplicate in toDelete {
                    // Move logs from duplicate to keeper
                    // IMPORTANT: We must fetch logs by habitID (denormalized field) because
                    // CloudKit syncs records independently and the SwiftData relationship
                    // (duplicate.logs) might not be populated after sync.
                    let duplicateId = duplicate.id
                    let logsDescriptor = FetchDescriptor<ActiveHabitLogModel>(
                        predicate: #Predicate { $0.habitID == duplicateId }
                    )
                    let logsToMove = try modelContext.fetch(logsDescriptor)

                    if !logsToMove.isEmpty {
                        logger.log(
                            "Moving logs from duplicate habit",
                            level: .info,
                            category: .dataIntegrity,
                            metadata: [
                                "from_habit": duplicate.name,
                                "from_id": duplicateId.uuidString,
                                "to_id": toKeep.id.uuidString,
                                "logs_count": logsToMove.count
                            ]
                        )

                        for log in logsToMove {
                            log.habit = toKeep
                            log.habitID = toKeep.id  // Update denormalized ID too
                        }
                    }

                    // Delete the duplicate habit
                    modelContext.delete(duplicate)
                    removedCount += 1
                }

                logger.log(
                    "Merged duplicate habits",
                    level: .info,
                    category: .dataIntegrity,
                    metadata: [
                        "kept": toKeep.name,
                        "keptId": toKeep.id.uuidString,
                        "deleted": toDelete.count
                    ]
                )
            }

            if removedCount > 0 {
                try modelContext.save()
            }

            return removedCount
        } catch {
            logger.log("Error deduplicating habits: \(error)", level: .error, category: .dataIntegrity)
            throw error
        }
    }

    public func deduplicateCategories() async throws -> Int {
        do {
            // Fetch all categories
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>()
            let allCategories = try modelContext.fetch(descriptor)

            // Group by ID to find duplicates
            let grouped = Dictionary(grouping: allCategories) { $0.id }

            var removedCount = 0

            for (categoryId, duplicates) in grouped where duplicates.count > 1 {
                logger.log(
                    "Found duplicate categories",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["id": categoryId, "count": duplicates.count]
                )

                // Keep the one with the most habits
                let sorted = duplicates.sorted { cat1, cat2 in
                    let habits1 = cat1.habits?.count ?? 0
                    let habits2 = cat2.habits?.count ?? 0
                    return habits1 > habits2
                }

                // Keep the first (best) one, delete the rest
                let toKeep = sorted[0]
                let toDelete = sorted.dropFirst()

                for duplicate in toDelete {
                    // Move habits from duplicate to keeper if any
                    if let habitsToMove = duplicate.habits {
                        for habit in habitsToMove {
                            habit.category = toKeep
                        }
                    }

                    // Delete the duplicate
                    modelContext.delete(duplicate)
                    removedCount += 1
                }

                logger.log(
                    "Merged duplicate categories",
                    level: .info,
                    category: .dataIntegrity,
                    metadata: [
                        "kept": toKeep.displayName,
                        "deleted": toDelete.count
                    ]
                )
            }

            if removedCount > 0 {
                try modelContext.save()
            }

            return removedCount
        } catch {
            logger.log("Error deduplicating categories: \(error)", level: .error, category: .dataIntegrity)
            throw error
        }
    }

    public func deduplicateHabitLogs() async throws -> Int {
        do {
            // Fetch all logs
            let descriptor = FetchDescriptor<ActiveHabitLogModel>()
            let allLogs = try modelContext.fetch(descriptor)

            var removedCount = 0

            // PHASE 1: Deduplicate by UUID (exact duplicates from CloudKit retry logic)
            let groupedByUUID = Dictionary(grouping: allLogs) { $0.id }

            for (logId, duplicates) in groupedByUUID where duplicates.count > 1 {
                logger.log(
                    "Found duplicate logs by UUID",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["id": logId.uuidString, "count": duplicates.count]
                )

                // Keep the one with the highest value (most progress) or most recent date
                let sorted = duplicates.sorted { log1, log2 in
                    let value1 = log1.value ?? 0
                    let value2 = log2.value ?? 0
                    if value1 != value2 {
                        return value1 > value2
                    }
                    return log1.date > log2.date
                }

                let toDelete = sorted.dropFirst()
                for duplicate in toDelete {
                    modelContext.delete(duplicate)
                    removedCount += 1
                }
            }

            // PHASE 2: Deduplicate by (habitID + date) - logs from different devices for same day
            // CloudKit creates new UUIDs when syncing, so two logs for the same habit on the same day
            // from different devices will have different UUIDs but represent the same logical entry.

            // Re-fetch after Phase 1 deletions to get clean state
            let remainingLogs = try modelContext.fetch(descriptor)

            // Group by (habitID + startOfDay)
            let groupedByHabitAndDate = Dictionary(grouping: remainingLogs) { log -> String in
                let dateKey = CalendarUtils.startOfDayLocal(for: log.date)
                return "\(log.habitID.uuidString)_\(dateKey.timeIntervalSince1970)"
            }

            for (key, duplicates) in groupedByHabitAndDate where duplicates.count > 1 {
                // Get habit info for logging
                let habitName = duplicates.first?.habit?.name ?? "Unknown"
                // kindRaw: 0 = binary, 1 = numeric
                let kindRaw = duplicates.first?.habit?.kindRaw ?? 0

                logger.log(
                    "Found duplicate logs for same habit+date",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: [
                        "habit": habitName,
                        "date": duplicates.first?.date.description ?? "unknown",
                        "count": duplicates.count,
                        "kind": kindRaw == 0 ? "binary" : "numeric"
                    ]
                )

                // Sort by value (highest first), then by date (most recent first)
                let sorted = duplicates.sorted { log1, log2 in
                    let value1 = log1.value ?? 0
                    let value2 = log2.value ?? 0
                    if value1 != value2 {
                        return value1 > value2
                    }
                    return log1.date > log2.date
                }

                // Keep the first (highest value), delete the rest
                let toKeep = sorted[0]
                let toDelete = sorted.dropFirst()

                for duplicate in toDelete {
                    modelContext.delete(duplicate)
                    removedCount += 1
                }

                logger.log(
                    "Merged duplicate logs for habit+date",
                    level: .info,
                    category: .dataIntegrity,
                    metadata: [
                        "habit": habitName,
                        "kept_value": toKeep.value ?? 0,
                        "deleted": toDelete.count
                    ]
                )
            }

            if removedCount > 0 {
                try modelContext.save()
            }

            return removedCount
        } catch {
            logger.log("Error deduplicating logs: \(error)", level: .error, category: .dataIntegrity)
            throw error
        }
    }

    public func deduplicateProfiles() async throws -> Int {
        do {
            // Fetch all user profiles
            let descriptor = FetchDescriptor<ActiveUserProfileModel>()
            let allProfiles = try modelContext.fetch(descriptor)

            // UserProfile is a singleton model - there should only be ONE profile per user.
            // If we have multiple profiles (e.g., from CloudKit sync creating duplicates
            // with different UUIDs), we merge data and keep the best one.
            guard allProfiles.count > 1 else {
                return 0
            }

            logger.log(
                "Found multiple user profiles - deduplicating",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["count": allProfiles.count]
            )

            // Sort profiles to determine which one to keep:
            // 1. Prefer profiles with a name set
            // 2. Prefer profiles with avatar data
            // 3. Prefer profiles with meaningful demographics (not "prefer_not_to_say")
            // 4. Prefer most recently updated
            // 5. Prefer oldest created (original profile)
            let sorted = allProfiles.sorted { profile1, profile2 in
                // Primary: prefer profile with name
                let hasName1 = !profile1.name.isEmpty
                let hasName2 = !profile2.name.isEmpty
                if hasName1 != hasName2 {
                    return hasName1
                }

                // Secondary: prefer profile with avatar
                let hasAvatar1 = profile1.avatarImageData != nil
                let hasAvatar2 = profile2.avatarImageData != nil
                if hasAvatar1 != hasAvatar2 {
                    return hasAvatar1
                }

                // Tertiary: prefer profile with meaningful demographics
                // "prefer_not_to_say" is valid but less informative than actual values
                let hasMeaningfulGender1 = profile1.gender != nil && profile1.gender != "prefer_not_to_say"
                let hasMeaningfulGender2 = profile2.gender != nil && profile2.gender != "prefer_not_to_say"
                if hasMeaningfulGender1 != hasMeaningfulGender2 {
                    return hasMeaningfulGender1
                }

                // Quaternary: prefer most recently updated
                if profile1.updatedAt != profile2.updatedAt {
                    return profile1.updatedAt > profile2.updatedAt
                }

                // Quinary: prefer oldest created (the original)
                return profile1.createdAt < profile2.createdAt
            }

            // Keep the first (best) one, merge data from others, then delete duplicates
            let toKeep = sorted[0]
            let toDelete = sorted.dropFirst()

            var removedCount = 0
            for duplicate in toDelete {
                // Merge data from duplicate into keeper to prevent data loss
                // Only merge if keeper is missing the data
                if toKeep.name.isEmpty && !duplicate.name.isEmpty {
                    toKeep.name = duplicate.name
                }

                if toKeep.avatarImageData == nil && duplicate.avatarImageData != nil {
                    toKeep.avatarImageData = duplicate.avatarImageData
                }

                // V11: Merge demographics if keeper is missing meaningful values
                // Prefer actual values over "prefer_not_to_say"
                let keeperHasMeaningfulGender = toKeep.gender != nil && toKeep.gender != "prefer_not_to_say"
                let duplicateHasMeaningfulGender = duplicate.gender != nil && duplicate.gender != "prefer_not_to_say"
                if !keeperHasMeaningfulGender && duplicateHasMeaningfulGender {
                    toKeep.gender = duplicate.gender
                }

                let keeperHasMeaningfulAgeGroup = toKeep.ageGroup != nil && toKeep.ageGroup != "prefer_not_to_say"
                let duplicateHasMeaningfulAgeGroup = duplicate.ageGroup != nil && duplicate.ageGroup != "prefer_not_to_say"
                if !keeperHasMeaningfulAgeGroup && duplicateHasMeaningfulAgeGroup {
                    toKeep.ageGroup = duplicate.ageGroup
                }

                // Keep the most recent updatedAt timestamp
                if duplicate.updatedAt > toKeep.updatedAt {
                    toKeep.updatedAt = duplicate.updatedAt
                }

                modelContext.delete(duplicate)
                removedCount += 1
            }

            if removedCount > 0 {
                try modelContext.save()
            }

            logger.log(
                "Merged duplicate user profiles",
                level: .info,
                category: .dataIntegrity,
                metadata: [
                    "kept_id": toKeep.id,
                    "has_name": !toKeep.name.isEmpty,
                    "has_avatar": toKeep.avatarImageData != nil,
                    "has_gender": toKeep.gender != nil,
                    "has_ageGroup": toKeep.ageGroup != nil,
                    "deleted": removedCount
                ]
            )

            // Warn if merged profile has no name (edge case - all duplicates were empty)
            if toKeep.name.isEmpty {
                logger.log(
                    "Merged profile has no name - user may need to set up profile",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["profile_id": toKeep.id]
                )
            }

            return removedCount
        } catch {
            logger.log("Error deduplicating profiles: \(error)", level: .error, category: .dataIntegrity)
            throw error
        }
    }
}
