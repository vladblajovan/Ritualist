//
//  ICloudSyncDiagnostics.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 27.11.2025.
//
//  Diagnostic tracking for iCloud sync events.
//  Used by Debug Menu to help diagnose sync issues.
//

import Foundation
import Observation

#if DEBUG

/// Tracks iCloud sync diagnostic information for debugging
/// This is a simple observable class that captures sync events for display in the Debug Menu
@MainActor @Observable
final class ICloudSyncDiagnostics {
    static let shared = ICloudSyncDiagnostics()

    /// Number of CloudKit silent push notifications received (via AppDelegate)
    private(set) var pushNotificationCount: Int = 0

    /// Last time a CloudKit push notification was received
    private(set) var lastPushNotificationDate: Date?

    /// Number of NSPersistentStoreRemoteChange notifications received
    private(set) var remoteChangeCount: Int = 0

    /// Last time a remote change notification was received
    private(set) var lastRemoteChangeDate: Date?

    /// Number of times deduplication has run
    private(set) var deduplicationRunCount: Int = 0

    /// Total number of duplicates removed across all deduplication runs
    private(set) var totalDuplicatesRemoved: Int = 0

    /// Last deduplication result
    private(set) var lastDeduplicationResult: String = "None"

    /// Whether remote notifications are registered
    private(set) var isRegisteredForRemoteNotifications: Bool = false

    private init() {}

    /// Called when remote notification registration succeeds
    func recordRemoteNotificationRegistration(success: Bool) {
        isRegisteredForRemoteNotifications = success
    }

    /// Called when CloudKit silent push notification is received (via AppDelegate)
    func recordPushNotification() {
        pushNotificationCount += 1
        lastPushNotificationDate = Date()
    }

    /// Called when NSPersistentStoreRemoteChange notification is received
    func recordRemoteChange() {
        remoteChangeCount += 1
        lastRemoteChangeDate = Date()
    }

    /// Called when deduplication completes
    func recordDeduplication(habitsRemoved: Int, categoriesRemoved: Int, logsRemoved: Int, profilesRemoved: Int) {
        deduplicationRunCount += 1
        let totalRemoved = habitsRemoved + categoriesRemoved + logsRemoved + profilesRemoved
        totalDuplicatesRemoved += totalRemoved

        if totalRemoved > 0 {
            lastDeduplicationResult = "Removed \(habitsRemoved)H, \(categoriesRemoved)C, \(logsRemoved)L, \(profilesRemoved)P"
        } else {
            lastDeduplicationResult = "No duplicates"
        }
    }

    /// Reset all diagnostics
    func reset() {
        pushNotificationCount = 0
        lastPushNotificationDate = nil
        remoteChangeCount = 0
        lastRemoteChangeDate = nil
        deduplicationRunCount = 0
        totalDuplicatesRemoved = 0
        lastDeduplicationResult = "None"
        // Note: isRegisteredForRemoteNotifications is not reset as it reflects actual registration state
    }
}

#endif
