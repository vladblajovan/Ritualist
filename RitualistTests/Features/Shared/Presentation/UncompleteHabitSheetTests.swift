//
//  UncompleteHabitSheetTests.swift
//  RitualistTests
//
//  Tests for UncompleteHabitSheet accessibility and behavior
//

import Foundation
import Testing
import SwiftUI
@testable import RitualistCore
@testable import Ritualist

/// Tests for UncompleteHabitSheet accessibility identifiers
@Suite("UncompleteHabitSheet - Accessibility Identifiers")
struct UncompleteHabitSheetAccessibilityTests {

    @Test("Sheet accessibility identifiers have correct format")
    func sheetAccessibilityIdentifiersHaveCorrectFormat() {
        // Verify the accessibility identifiers follow the dot notation convention
        #expect(AccessibilityID.Sheet.uncompleteHabit == "sheet.uncompleteHabit")
        #expect(AccessibilityID.Sheet.uncompleteHabitConfirmButton == "sheet.uncompleteHabit.confirm")
        #expect(AccessibilityID.Sheet.uncompleteHabitCancelButton == "sheet.uncompleteHabit.cancel")
    }

    @Test("Confirm button identifier is distinct from cancel button")
    func confirmButtonIdentifierIsDistinctFromCancelButton() {
        let confirmId = AccessibilityID.Sheet.uncompleteHabitConfirmButton
        let cancelId = AccessibilityID.Sheet.uncompleteHabitCancelButton

        #expect(confirmId != cancelId)
        #expect(confirmId.contains("confirm"))
        #expect(cancelId.contains("cancel"))
    }

    @Test("All sheet identifiers share common prefix")
    func allSheetIdentifiersShareCommonPrefix() {
        let sheetPrefix = "sheet.uncompleteHabit"

        #expect(AccessibilityID.Sheet.uncompleteHabit.hasPrefix("sheet."))
        #expect(AccessibilityID.Sheet.uncompleteHabitConfirmButton.hasPrefix(sheetPrefix))
        #expect(AccessibilityID.Sheet.uncompleteHabitCancelButton.hasPrefix(sheetPrefix))
    }
}

/// Tests for UncompleteHabitSheet VoiceOver support
@Suite("UncompleteHabitSheet - VoiceOver")
struct UncompleteHabitSheetVoiceOverTests {

    @Test("VoiceOver announcement delay uses AccessibilityConfig constant")
    func voiceOverAnnouncementDelayUsesAccessibilityConfig() {
        // The delay should be defined in AccessibilityConfig
        let delay = AccessibilityConfig.voiceOverAnnouncementDelay

        // Should be 0.5 seconds as documented
        #expect(delay == 0.5)
    }

    @Test("VoiceOver announcement delay is positive")
    func voiceOverAnnouncementDelayIsPositive() {
        let delay = AccessibilityConfig.voiceOverAnnouncementDelay
        #expect(delay > 0)
    }

    @Test("VoiceOver announcement delay is reasonable for UI transitions")
    func voiceOverAnnouncementDelayIsReasonableForUITransitions() {
        let delay = AccessibilityConfig.voiceOverAnnouncementDelay

        // Should be between 0.1s (too fast) and 2.0s (too slow)
        #expect(delay >= 0.1)
        #expect(delay <= 2.0)
    }
}

/// Tests for UncompleteHabitSheet localization strings
@Suite("UncompleteHabitSheet - Localization")
struct UncompleteHabitSheetLocalizationTests {

    @Test("Strings namespace exists for UncompleteHabitSheet")
    func stringsNamespaceExistsForUncompleteHabitSheet() {
        // Verify the Strings enum has UncompleteHabitSheet namespace
        // This is a compile-time check
        let _ = Strings.UncompleteHabitSheet.self
        #expect(true)
    }

    @Test("Screen changed announcement includes habit name")
    func screenChangedAnnouncementIncludesHabitName() {
        let habitName = "Morning Meditation"
        let announcement = Strings.UncompleteHabitSheet.screenChangedAnnouncement(habitName)

        // The announcement should contain the habit name for context
        #expect(announcement.contains(habitName) || announcement.lowercased().contains("meditation"))
    }

    @Test("Common cancel string exists")
    func commonCancelStringExists() {
        let cancelText = Strings.Common.cancel
        #expect(!cancelText.isEmpty)
    }
}

/// Tests for habit creation for UncompleteHabitSheet testing
@Suite("UncompleteHabitSheet - Test Data")
struct UncompleteHabitSheetTestDataTests {

    @Test("Binary habit can be created for sheet testing")
    func binaryHabitCanBeCreatedForSheetTesting() {
        let habit = Habit(
            id: UUID(),
            name: "Test Habit",
            emoji: "✅",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: 1.0,
            schedule: .daily,
            isActive: true,
            categoryId: nil,
            suggestionId: nil
        )

        #expect(habit.kind == .binary)
        #expect(habit.name == "Test Habit")
        #expect(habit.emoji == "✅")
    }

    @Test("Habit with emoji displays correctly")
    func habitWithEmojiDisplaysCorrectly() {
        let testEmojis = ["🧘", "💪", "📚", "🏃", "💧"]

        for emoji in testEmojis {
            let habit = Habit(
                id: UUID(),
                name: "Test",
                emoji: emoji,
                kind: .binary,
                unitLabel: nil,
                dailyTarget: 1.0,
                schedule: .daily,
                isActive: true,
                categoryId: nil,
                suggestionId: nil
            )
            #expect(habit.emoji == emoji)
        }
    }

    @Test("Habit without emoji uses nil")
    func habitWithoutEmojiUsesNil() {
        let habit = Habit(
            id: UUID(),
            name: "No Emoji Habit",
            emoji: nil,
            kind: .binary,
            unitLabel: nil,
            dailyTarget: 1.0,
            schedule: .daily,
            isActive: true,
            categoryId: nil,
            suggestionId: nil
        )

        #expect(habit.emoji == nil)
    }
}
