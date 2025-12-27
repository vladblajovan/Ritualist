//
//  InspirationDismissalStoreTests.swift
//  RitualistTests
//
//  Tests for InspirationDismissalStore service.
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - Load/Save Tests

@Suite("InspirationDismissalStore - Persistence")
struct InspirationDismissalStorePersistenceTests {

    @Test("Loads empty set when no data stored")
    func loadsEmptyWhenNoData() {
        let userDefaults = MockUserDefaultsService()
        let store = InspirationDismissalStore(
            userDefaults: userDefaults,
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let dismissed = store.loadDismissedTriggers()

        #expect(dismissed.isEmpty, "Should return empty set when no data stored")
    }

    @Test("Saves and loads triggers correctly")
    func savesAndLoadsTriggers() {
        let userDefaults = MockUserDefaultsService()
        let store = InspirationDismissalStore(
            userDefaults: userDefaults,
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let triggersToSave: Set<InspirationTrigger> = [.perfectDay, .morningMotivation]
        store.saveDismissedTriggers(triggersToSave)

        let loaded = store.loadDismissedTriggers()

        #expect(loaded == triggersToSave, "Should load same triggers that were saved")
    }

    @Test("Overwrites previous triggers on save")
    func overwritesPreviousTriggers() {
        let userDefaults = MockUserDefaultsService()
        let store = InspirationDismissalStore(
            userDefaults: userDefaults,
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        store.saveDismissedTriggers([.perfectDay])
        store.saveDismissedTriggers([.weekendMotivation])

        let loaded = store.loadDismissedTriggers()

        #expect(loaded == [.weekendMotivation], "Should have only the latest saved triggers")
        #expect(!loaded.contains(.perfectDay), "Should not contain previously saved trigger")
    }

    @Test("Handles empty set save")
    func handlesEmptySetSave() {
        let userDefaults = MockUserDefaultsService()
        let store = InspirationDismissalStore(
            userDefaults: userDefaults,
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        store.saveDismissedTriggers([.perfectDay])
        store.saveDismissedTriggers([])

        let loaded = store.loadDismissedTriggers()

        #expect(loaded.isEmpty, "Should be empty after saving empty set")
    }
}

// MARK: - Reset If New Day Tests

@Suite("InspirationDismissalStore - Day Reset")
struct InspirationDismissalStoreDayResetTests {

    @Test("First call sets reset date and returns false")
    func firstCallSetsResetDate() {
        let userDefaults = MockUserDefaultsService()
        let store = InspirationDismissalStore(
            userDefaults: userDefaults,
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let wasReset = store.resetIfNewDay(timezone: .current)

        #expect(!wasReset, "First call should return false (no reset needed)")
        #expect(store.lastResetDate() != nil, "Should have set reset date")
    }

    @Test("Same day returns false without reset")
    func sameDayNoReset() {
        let userDefaults = MockUserDefaultsService()
        let store = InspirationDismissalStore(
            userDefaults: userDefaults,
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        // First call - sets date
        _ = store.resetIfNewDay(timezone: .current)

        // Same day call
        let wasReset = store.resetIfNewDay(timezone: .current)

        #expect(!wasReset, "Same day should not trigger reset")
    }

    @Test("Last reset date returns nil initially")
    func lastResetDateNilInitially() {
        let userDefaults = MockUserDefaultsService()
        let store = InspirationDismissalStore(
            userDefaults: userDefaults,
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let lastReset = store.lastResetDate()

        #expect(lastReset == nil, "Should be nil before first reset check")
    }
}
