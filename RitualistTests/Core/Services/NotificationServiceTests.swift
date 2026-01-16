//
//  NotificationServiceTests.swift
//  RitualistTests
//
//  Tests for notification content generation and helper utilities.
//  Focuses on testable pure logic components of the notification system.
//
//  Key Testing Focus:
//  - HabitReminderNotificationContentGenerator contextual titles
//  - Streak milestone content generation
//  - PersonalityNotificationContentGenerator trait-based content
//  - NotificationAuthorizationStatus mapping
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - Habit Reminder Content Generator Tests

@Suite("HabitReminderNotificationContentGenerator - Contextual Titles", .tags(.notifications, .businessLogic))
struct HabitReminderContentGeneratorContextualTitleTests {

    @Test("Morning habit (before 9am) generates morning-themed content")
    func morningHabit_generatesMorningContent() {
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 7, minute: 0)

        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: habitID,
            habitName: "Exercise",
            reminderTime: reminderTime,
            isWeekend: false
        )

        #expect(content.title.contains("Morning"))
        #expect(content.title.contains("🌅"))
        #expect(content.body.contains("07:00"))
        #expect(content.body.contains("Good morning"))
    }

    @Test("Midday habit (9am-5pm) generates midday-themed content")
    func middayHabit_generatesMiddayContent() {
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 14, minute: 30)

        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: habitID,
            habitName: "Read",
            reminderTime: reminderTime,
            isWeekend: false
        )

        #expect(content.title.contains("Midday"))
        #expect(content.title.contains("☀️"))
        #expect(content.body.contains("14:30"))
        #expect(content.body.contains("You've got this"))
    }

    @Test("Evening habit (after 5pm) generates evening-themed content")
    func eveningHabit_generatesEveningContent() {
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 20, minute: 0)

        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: habitID,
            habitName: "Meditate",
            reminderTime: reminderTime,
            isWeekend: false
        )

        #expect(content.title.contains("Evening"))
        #expect(content.title.contains("🌙"))
        #expect(content.body.contains("20:00"))
        #expect(content.body.contains("Wind down"))
    }

    @Test("Weekend habit generates weekend-themed content")
    func weekendHabit_generatesWeekendContent() {
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 10, minute: 0)

        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: habitID,
            habitName: "Yoga",
            reminderTime: reminderTime,
            isWeekend: true
        )

        #expect(content.title.contains("Weekend"))
        #expect(content.title.contains("🌟"))
        #expect(content.body.contains("momentum"))
    }

    @Test("Habit with streak includes day count in body")
    func habitWithStreak_includesDayCount() {
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 9, minute: 30)

        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: habitID,
            habitName: "Journal",
            reminderTime: reminderTime,
            currentStreak: 5,
            isWeekend: false
        )

        #expect(content.body.contains("Day 6")) // currentStreak + 1
    }

    @Test("Content includes correct userInfo metadata")
    func content_includesCorrectUserInfo() {
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 12, minute: 0)

        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: habitID,
            habitName: "Stretch",
            reminderTime: reminderTime,
            habitCategory: "Health",
            currentStreak: 3
        )

        let userInfo = content.userInfo
        #expect(userInfo["type"] as? String == "habit_reminder")
        #expect(userInfo["habitId"] as? String == habitID.uuidString)
        #expect(userInfo["habitName"] as? String == "Stretch")
        #expect(userInfo["reminderHour"] as? Int == 12)
        #expect(userInfo["reminderMinute"] as? Int == 0)
        #expect(userInfo["habitCategory"] as? String == "Health")
        #expect(userInfo["currentStreak"] as? Int == 3)
    }
}

// MARK: - Streak Milestone Content Tests

@Suite("HabitReminderNotificationContentGenerator - Streak Milestones", .tags(.notifications, .streaks))
struct HabitReminderContentGeneratorStreakMilestoneTests {

    @Test("3-day streak shows fire emoji and momentum message")
    func threeDayStreak_showsFireEmojiAndMomentum() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Exercise",
            streakDays: 3
        )

        #expect(content.title.contains("🔥"))
        #expect(content.title.contains("3-Day Streak"))
        #expect(content.body.contains("momentum"))
    }

    @Test("7-day streak shows rocket emoji and week message")
    func sevenDayStreak_showsRocketEmojiAndWeekMessage() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Reading",
            streakDays: 7
        )

        #expect(content.title.contains("🚀"))
        #expect(content.title.contains("7-Day Streak"))
        #expect(content.body.contains("week"))
    }

    @Test("14-day streak shows diamond emoji")
    func fourteenDayStreak_showsDiamondEmoji() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Meditation",
            streakDays: 14
        )

        #expect(content.title.contains("💎"))
        #expect(content.title.contains("14-Day Streak"))
        #expect(content.body.contains("Two weeks"))
    }

    @Test("21-day streak shows crown emoji and lasting habit message")
    func twentyOneDayStreak_showsCrownAndLastingHabit() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Journal",
            streakDays: 21
        )

        #expect(content.title.contains("👑"))
        #expect(content.title.contains("21-Day"))
        #expect(content.body.contains("lasting habit"))
    }

    @Test("30-day streak shows trophy emoji and champion message")
    func thirtyDayStreak_showsTrophyAndChampion() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Workout",
            streakDays: 30
        )

        #expect(content.title.contains("🏆"))
        #expect(content.title.contains("30"))
        #expect(content.body.contains("champion"))
    }

    @Test("100-day streak shows star emoji and mastered message")
    func hundredDayStreak_showsStarAndMastered() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Running",
            streakDays: 100
        )

        #expect(content.title.contains("🌟"))
        #expect(content.title.contains("100"))
        #expect(content.body.contains("mastered"))
    }

    @Test("365+ day streak shows medal emoji and legend message")
    func yearPlusStreak_showsMedalAndLegend() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Healthy Eating",
            streakDays: 400
        )

        #expect(content.title.contains("🏅"))
        #expect(content.title.contains("400"))
        #expect(content.body.contains("legend"))
    }

    @Test("Streak milestone content includes habit name in body")
    func streakMilestone_includesHabitNameInBody() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Push-ups",
            streakDays: 7
        )

        #expect(content.body.contains("Push-ups"))
    }

    @Test("Streak milestone content has correct category identifier")
    func streakMilestone_hasCorrectCategoryIdentifier() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Walk",
            streakDays: 14
        )

        #expect(content.categoryIdentifier == "HABIT_STREAK_MILESTONE")
    }

    @Test("Streak milestone content has correct userInfo")
    func streakMilestone_hasCorrectUserInfo() {
        let habitID = UUID()

        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: "Study",
            streakDays: 50
        )

        let userInfo = content.userInfo
        #expect(userInfo["type"] as? String == "habit_streak_milestone")
        #expect(userInfo["habitId"] as? String == habitID.uuidString)
        #expect(userInfo["habitName"] as? String == "Study")
        #expect(userInfo["streakDays"] as? Int == 50)
    }
}

// MARK: - Personality Notification Content Generator Tests

@Suite("PersonalityNotificationContentGenerator - Trait Content", .tags(.notifications, .profile))
struct PersonalityNotificationContentGeneratorTraitContentTests {

    func createProfile(
        dominantTrait: PersonalityTrait,
        confidence: ConfidenceLevel = .high
    ) -> PersonalityProfile {
        PersonalityProfile(
            id: UUID(),
            userId: UUID(),
            traitScores: [dominantTrait: 0.8],
            dominantTrait: dominantTrait,
            confidence: confidence,
            analysisMetadata: AnalysisMetadata(
                analysisDate: Date(),
                dataPointsAnalyzed: 100,
                timeRangeAnalyzed: 30,
                version: "1.0"
            )
        )
    }

    @Test("Openness dominant trait generates creative mind content")
    func opennessDominant_generatesCreativeMindContent() {
        let profile = createProfile(dominantTrait: .openness)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("Creative Mind"))
        #expect(content.body.contains("openness"))
    }

    @Test("Conscientiousness dominant trait generates disciplined achiever content")
    func conscientiousnessDominant_generatesDisciplinedAchieverContent() {
        let profile = createProfile(dominantTrait: .conscientiousness)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("Disciplined Achiever"))
        #expect(content.body.contains("conscientiousness"))
    }

    @Test("Extraversion dominant trait generates social energy content")
    func extraversionDominant_generatesSocialEnergyContent() {
        let profile = createProfile(dominantTrait: .extraversion)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("Social Energy"))
        #expect(content.body.contains("extraverted"))
    }

    @Test("Agreeableness dominant trait generates compassionate builder content")
    func agreeablenessDominant_generatesCompassionateBuilderContent() {
        let profile = createProfile(dominantTrait: .agreeableness)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("Compassionate Builder"))
        #expect(content.body.contains("agreeableness"))
    }

    @Test("Neuroticism dominant trait generates sensitive insights content")
    func neuroticismDominant_generatesSensitiveInsightsContent() {
        let profile = createProfile(dominantTrait: .neuroticism)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("Sensitive Insights"))
        #expect(content.body.contains("stress") || content.body.contains("emotions"))
    }
}

// MARK: - Personality Notification Confidence Tests

@Suite("PersonalityNotificationContentGenerator - Confidence Levels", .tags(.notifications, .profile))
struct PersonalityNotificationContentGeneratorConfidenceTests {

    func createProfile(confidence: ConfidenceLevel) -> PersonalityProfile {
        PersonalityProfile(
            id: UUID(),
            userId: UUID(),
            traitScores: [.conscientiousness: 0.8],
            dominantTrait: .conscientiousness,
            confidence: confidence,
            analysisMetadata: AnalysisMetadata(
                analysisDate: Date(),
                dataPointsAnalyzed: 100,
                timeRangeAnalyzed: 30,
                version: "1.0"
            )
        )
    }

    @Test("Very high confidence shows target emoji")
    func veryHighConfidence_showsTargetEmoji() {
        let profile = createProfile(confidence: .veryHigh)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("🎯"))
    }

    @Test("High confidence shows target emoji")
    func highConfidence_showsTargetEmoji() {
        let profile = createProfile(confidence: .high)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("🎯"))
    }

    @Test("Medium confidence shows chart emoji")
    func mediumConfidence_showsChartEmoji() {
        let profile = createProfile(confidence: .medium)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("📊"))
    }

    @Test("Low confidence shows magnifying glass emoji")
    func lowConfidence_showsMagnifyingGlassEmoji() {
        let profile = createProfile(confidence: .low)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.title.contains("🔍"))
    }

    @Test("Content includes correct userInfo for deep linking")
    func content_includesCorrectUserInfoForDeepLinking() {
        let profile = createProfile(confidence: .high)

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        let userInfo = content.userInfo
        #expect(userInfo["type"] as? String == "personality_analysis")
        #expect(userInfo["action"] as? String == "open_analysis")
        #expect(userInfo["dominant_trait"] as? String == "conscientiousness")
        #expect(userInfo["confidence"] as? String == "high")
    }

    @Test("Content has correct category identifier based on trait")
    func content_hasCorrectCategoryIdentifierBasedOnTrait() {
        let profile = PersonalityProfile(
            id: UUID(),
            userId: UUID(),
            traitScores: [.openness: 0.8],
            dominantTrait: .openness,
            confidence: .high,
            analysisMetadata: AnalysisMetadata(
                analysisDate: Date(),
                dataPointsAnalyzed: 100,
                timeRangeAnalyzed: 30,
                version: "1.0"
            )
        )

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.categoryIdentifier == "PERSONALITY_ANALYSIS_OPENNESS")
    }
}

// MARK: - Insufficient Data Content Tests

@Suite("PersonalityNotificationContentGenerator - Insufficient Data", .tags(.notifications, .profile))
struct PersonalityNotificationContentGeneratorInsufficientDataTests {

    @Test("Insufficient data content has seedling emoji")
    func insufficientData_hasSeedlingEmoji() {
        let content = PersonalityNotificationContentGenerator.generateInsufficientDataContent()

        #expect(content.title.contains("🌱"))
    }

    @Test("Insufficient data content encourages continued tracking")
    func insufficientData_encouragesContinuedTracking() {
        let content = PersonalityNotificationContentGenerator.generateInsufficientDataContent()

        #expect(content.body.contains("progress") || content.body.contains("tracking"))
    }

    @Test("Insufficient data content has correct category identifier")
    func insufficientData_hasCorrectCategoryIdentifier() {
        let content = PersonalityNotificationContentGenerator.generateInsufficientDataContent()

        #expect(content.categoryIdentifier == "PERSONALITY_ANALYSIS_INSUFFICIENT_DATA")
    }

    @Test("Insufficient data content has correct userInfo for deep linking")
    func insufficientData_hasCorrectUserInfoForDeepLinking() {
        let content = PersonalityNotificationContentGenerator.generateInsufficientDataContent()

        let userInfo = content.userInfo
        #expect(userInfo["type"] as? String == "personality_analysis")
        #expect(userInfo["action"] as? String == "open_requirements")
    }
}

// MARK: - Notification Authorization Status Tests

@Suite("NotificationAuthorizationStatus - Mapping", .tags(.notifications))
struct NotificationAuthorizationStatusTests {

    @Test("NotificationAuthorizationStatus has expected cases")
    func status_hasExpectedCases() {
        // Verify all expected cases exist
        let notDetermined = NotificationAuthorizationStatus.notDetermined
        let denied = NotificationAuthorizationStatus.denied
        let authorized = NotificationAuthorizationStatus.authorized
        let provisional = NotificationAuthorizationStatus.provisional
        let ephemeral = NotificationAuthorizationStatus.ephemeral

        #expect(notDetermined == .notDetermined)
        #expect(denied == .denied)
        #expect(authorized == .authorized)
        #expect(provisional == .provisional)
        #expect(ephemeral == .ephemeral)
    }
}

// MARK: - Content Property Tests

@Suite("Notification Content - Common Properties", .tags(.notifications))
struct NotificationContentCommonPropertiesTests {

    @Test("Habit reminder content has default sound")
    func habitReminderContent_hasDefaultSound() {
        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: UUID(),
            habitName: "Test",
            reminderTime: ReminderTime(hour: 10, minute: 0)
        )

        #expect(content.sound == .default)
    }

    @Test("Habit reminder content has no badge (prevents stale badges after reinstall)")
    func habitReminderContent_hasNoBadge() {
        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: UUID(),
            habitName: "Test",
            reminderTime: ReminderTime(hour: 10, minute: 0)
        )

        // Badge is intentionally nil - iOS doesn't clear pending notifications on uninstall,
        // so badges set by notifications would appear after reinstall. Badge count is now
        // managed via updateBadgeCount() when app becomes active.
        #expect(content.badge == nil)
    }

    @Test("Habit reminder content has relevance score of 1.0")
    func habitReminderContent_hasRelevanceScoreOfOne() {
        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: UUID(),
            habitName: "Test",
            reminderTime: ReminderTime(hour: 10, minute: 0)
        )

        #expect(content.relevanceScore == 1.0)
    }

    @Test("Habit reminder content has thread identifier for grouping")
    func habitReminderContent_hasThreadIdentifierForGrouping() {
        let habitID = UUID()
        let content = HabitReminderNotificationContentGenerator.generateContent(
            for: habitID,
            habitName: "Test",
            reminderTime: ReminderTime(hour: 10, minute: 0)
        )

        #expect(content.threadIdentifier == "habit_reminders_\(habitID.uuidString)")
    }

    @Test("Personality content has thread identifier for grouping")
    func personalityContent_hasThreadIdentifierForGrouping() {
        let profile = PersonalityProfile(
            id: UUID(),
            userId: UUID(),
            traitScores: [.openness: 0.8],
            dominantTrait: .openness,
            confidence: .high,
            analysisMetadata: AnalysisMetadata(
                analysisDate: Date(),
                dataPointsAnalyzed: 100,
                timeRangeAnalyzed: 30,
                version: "1.0"
            )
        )

        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)

        #expect(content.threadIdentifier == "personality_analysis")
    }
}
