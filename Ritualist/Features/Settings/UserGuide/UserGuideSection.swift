//
//  UserGuideSection.swift
//  Ritualist
//
//  Data model for guide sections in the User Guide.
//

import SwiftUI

struct UserGuideSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let items: [UserGuideItem]

    static let allSections: [UserGuideSection] = [
        gettingStarted,
        trackingHabits,
        remindersAndNotifications,
        insightsAndStats,
        tipsAndTricks
    ]

    // MARK: - Section Definitions

    static let gettingStarted = UserGuideSection(
        title: String(localized: "userGuide.section.gettingStarted"),
        icon: "star.fill",
        color: .yellow,
        items: [
            UserGuideItem(
                title: String(localized: "userGuide.item.createHabit.title"),
                subtitle: String(localized: "userGuide.item.createHabit.subtitle"),
                emoji: "➕",
                content: String(localized: "userGuide.item.createHabit.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.habitTypes.title"),
                subtitle: String(localized: "userGuide.item.habitTypes.subtitle"),
                emoji: "🔢",
                content: String(localized: "userGuide.item.habitTypes.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.scheduling.title"),
                subtitle: String(localized: "userGuide.item.scheduling.subtitle"),
                emoji: "📅",
                content: String(localized: "userGuide.item.scheduling.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.categories.title"),
                subtitle: String(localized: "userGuide.item.categories.subtitle"),
                emoji: "🏷️",
                content: String(localized: "userGuide.item.categories.content")
            )
        ]
    )

    static let trackingHabits = UserGuideSection(
        title: String(localized: "userGuide.section.trackingHabits"),
        icon: "checkmark.circle.fill",
        color: .green,
        items: [
            UserGuideItem(
                title: String(localized: "userGuide.item.logHabit.title"),
                subtitle: String(localized: "userGuide.item.logHabit.subtitle"),
                emoji: "✅",
                content: String(localized: "userGuide.item.logHabit.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.quickLog.title"),
                subtitle: String(localized: "userGuide.item.quickLog.subtitle"),
                emoji: "⚡",
                content: String(localized: "userGuide.item.quickLog.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.streaks.title"),
                subtitle: String(localized: "userGuide.item.streaks.subtitle"),
                emoji: "🔥",
                content: String(localized: "userGuide.item.streaks.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.pastDays.title"),
                subtitle: String(localized: "userGuide.item.pastDays.subtitle"),
                emoji: "📆",
                content: String(localized: "userGuide.item.pastDays.content")
            )
        ]
    )

    static let remindersAndNotifications = UserGuideSection(
        title: String(localized: "userGuide.section.reminders"),
        icon: "bell.fill",
        color: .orange,
        items: [
            UserGuideItem(
                title: String(localized: "userGuide.item.timeReminders.title"),
                subtitle: String(localized: "userGuide.item.timeReminders.subtitle"),
                emoji: "⏰",
                content: String(localized: "userGuide.item.timeReminders.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.locationReminders.title"),
                subtitle: String(localized: "userGuide.item.locationReminders.subtitle"),
                emoji: "📍",
                content: String(localized: "userGuide.item.locationReminders.content")
            )
        ]
    )

    static let insightsAndStats = UserGuideSection(
        title: String(localized: "userGuide.section.insights"),
        icon: "chart.bar.fill",
        color: .blue,
        items: [
            UserGuideItem(
                title: String(localized: "userGuide.item.progressTrend.title"),
                subtitle: String(localized: "userGuide.item.progressTrend.subtitle"),
                emoji: "📈",
                content: String(localized: "userGuide.item.progressTrend.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.habitPatterns.title"),
                subtitle: String(localized: "userGuide.item.habitPatterns.subtitle"),
                emoji: "📊",
                content: String(localized: "userGuide.item.habitPatterns.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.heatmap.title"),
                subtitle: String(localized: "userGuide.item.heatmap.subtitle"),
                emoji: "🗓️",
                content: String(localized: "userGuide.item.heatmap.content")
            )
        ]
    )

    static let tipsAndTricks = UserGuideSection(
        title: String(localized: "userGuide.section.tips"),
        icon: "lightbulb.fill",
        color: .purple,
        items: [
            UserGuideItem(
                title: String(localized: "userGuide.item.startSmall.title"),
                subtitle: String(localized: "userGuide.item.startSmall.subtitle"),
                emoji: "🌱",
                content: String(localized: "userGuide.item.startSmall.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.habitStacking.title"),
                subtitle: String(localized: "userGuide.item.habitStacking.subtitle"),
                emoji: "🧱",
                content: String(localized: "userGuide.item.habitStacking.content")
            ),
            UserGuideItem(
                title: String(localized: "userGuide.item.twoMinRule.title"),
                subtitle: String(localized: "userGuide.item.twoMinRule.subtitle"),
                emoji: "⏱️",
                content: String(localized: "userGuide.item.twoMinRule.content")
            )
        ]
    )
}
