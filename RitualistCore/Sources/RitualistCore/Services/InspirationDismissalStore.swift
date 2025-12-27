//
//  InspirationDismissalStore.swift
//  Ritualist
//
//  Handles persistence of dismissed inspiration triggers.
//  Extracted for testability and reusability.
//

import Foundation

// MARK: - InspirationDismissalStore Protocol

public protocol InspirationDismissalStoreProtocol {
    /// Load dismissed triggers from storage
    func loadDismissedTriggers() -> Set<InspirationTrigger>

    /// Save dismissed triggers to storage
    func saveDismissedTriggers(_ triggers: Set<InspirationTrigger>)

    /// Check if it's a new day and reset if needed
    /// Returns true if triggers were reset
    func resetIfNewDay(timezone: TimeZone) -> Bool

    /// Get the last reset date
    func lastResetDate() -> Date?
}

// MARK: - InspirationDismissalStore

/// Default implementation using UserDefaults
public final class InspirationDismissalStore: InspirationDismissalStoreProtocol {

    private let userDefaults: UserDefaultsService
    private let logger: DebugLogger

    public init(
        userDefaults: UserDefaultsService,
        logger: DebugLogger
    ) {
        self.userDefaults = userDefaults
        self.logger = logger
    }

    public func loadDismissedTriggers() -> Set<InspirationTrigger> {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.dismissedTriggersToday) else {
            return []
        }

        do {
            let triggerStrings = try JSONDecoder().decode([String].self, from: data)
            let triggers = Set(triggerStrings.compactMap { string in
                InspirationTrigger.allCases.first { "\($0)" == string }
            })
            return triggers
        } catch {
            logger.log(
                "Failed to decode dismissed triggers",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            return []
        }
    }

    public func saveDismissedTriggers(_ triggers: Set<InspirationTrigger>) {
        let triggerStrings = triggers.map { "\($0)" }

        do {
            let data = try JSONEncoder().encode(triggerStrings)
            userDefaults.set(data, forKey: UserDefaultsKeys.dismissedTriggersToday)
        } catch {
            logger.log(
                "Failed to encode dismissed triggers",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    public func resetIfNewDay(timezone: TimeZone) -> Bool {
        let today = Date()

        guard let lastReset = userDefaults.date(forKey: UserDefaultsKeys.lastInspirationResetDate) else {
            // First time - set the reset date
            userDefaults.set(today, forKey: UserDefaultsKeys.lastInspirationResetDate)
            return false
        }

        if !CalendarUtils.areSameDayLocal(lastReset, today, timezone: timezone) {
            // New day - reset
            userDefaults.set(today, forKey: UserDefaultsKeys.lastInspirationResetDate)
            // Clear the dismissed triggers
            userDefaults.removeObject(forKey: UserDefaultsKeys.dismissedTriggersToday)
            return true
        }

        return false
    }

    public func lastResetDate() -> Date? {
        userDefaults.date(forKey: UserDefaultsKeys.lastInspirationResetDate)
    }
}

