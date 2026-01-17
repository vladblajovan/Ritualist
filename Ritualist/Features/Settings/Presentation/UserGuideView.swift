//
//  UserGuideView.swift
//  Ritualist
//
//  A searchable user guide with organized sections and quick navigation.
//

import SwiftUI
import RitualistCore

/// User guide with searchable sections
struct UserGuideView: View {
    @State private var searchText = ""

    private var filteredSections: [GuideSection] {
        if searchText.isEmpty {
            return GuideSection.allSections
        }
        return GuideSection.allSections.filter { section in
            section.title.localizedCaseInsensitiveContains(searchText) ||
            section.items.contains { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            // Guide Sections
            ForEach(filteredSections) { section in
                Section {
                    ForEach(section.items) { item in
                        GuideItemRow(item: item, searchText: searchText)
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .foregroundColor(section.color)
                        Text(section.title)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: Strings.UserGuide.searchPlaceholder)
        .navigationTitle(Strings.UserGuide.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Guide Item Row

private struct GuideItemRow: View {
    let item: GuideItem
    let searchText: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(item.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .textSelection(.enabled)
        } label: {
            HStack(spacing: 12) {
                if let emoji = item.emoji {
                    Text(emoji)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            // Auto-expand items that match search, collapse when search is cleared
            if !newValue.isEmpty &&
               (item.title.localizedCaseInsensitiveContains(newValue) ||
                item.content.localizedCaseInsensitiveContains(newValue)) {
                isExpanded = true
            } else if newValue.isEmpty {
                isExpanded = false
            }
        }
    }
}

// MARK: - Data Models

struct GuideSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let items: [GuideItem]

    static let allSections: [GuideSection] = [
        gettingStarted,
        trackingHabits,
        remindersAndNotifications,
        insightsAndStats,
        tipsAndTricks
    ]

    // MARK: - Section Definitions

    static let gettingStarted = GuideSection(
        title: String(localized: "userGuide.section.gettingStarted"),
        icon: "star.fill",
        color: .yellow,
        items: [
            GuideItem(
                title: String(localized: "userGuide.item.createHabit.title"),
                subtitle: String(localized: "userGuide.item.createHabit.subtitle"),
                emoji: "➕",
                content: String(localized: "userGuide.item.createHabit.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.habitTypes.title"),
                subtitle: String(localized: "userGuide.item.habitTypes.subtitle"),
                emoji: "🔢",
                content: String(localized: "userGuide.item.habitTypes.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.scheduling.title"),
                subtitle: String(localized: "userGuide.item.scheduling.subtitle"),
                emoji: "📅",
                content: String(localized: "userGuide.item.scheduling.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.categories.title"),
                subtitle: String(localized: "userGuide.item.categories.subtitle"),
                emoji: "🏷️",
                content: String(localized: "userGuide.item.categories.content")
            )
        ]
    )

    static let trackingHabits = GuideSection(
        title: String(localized: "userGuide.section.trackingHabits"),
        icon: "checkmark.circle.fill",
        color: .green,
        items: [
            GuideItem(
                title: String(localized: "userGuide.item.logHabit.title"),
                subtitle: String(localized: "userGuide.item.logHabit.subtitle"),
                emoji: "✅",
                content: String(localized: "userGuide.item.logHabit.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.quickLog.title"),
                subtitle: String(localized: "userGuide.item.quickLog.subtitle"),
                emoji: "⚡",
                content: String(localized: "userGuide.item.quickLog.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.streaks.title"),
                subtitle: String(localized: "userGuide.item.streaks.subtitle"),
                emoji: "🔥",
                content: String(localized: "userGuide.item.streaks.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.pastDays.title"),
                subtitle: String(localized: "userGuide.item.pastDays.subtitle"),
                emoji: "📆",
                content: String(localized: "userGuide.item.pastDays.content")
            )
        ]
    )

    static let remindersAndNotifications = GuideSection(
        title: String(localized: "userGuide.section.reminders"),
        icon: "bell.fill",
        color: .orange,
        items: [
            GuideItem(
                title: String(localized: "userGuide.item.timeReminders.title"),
                subtitle: String(localized: "userGuide.item.timeReminders.subtitle"),
                emoji: "⏰",
                content: String(localized: "userGuide.item.timeReminders.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.locationReminders.title"),
                subtitle: String(localized: "userGuide.item.locationReminders.subtitle"),
                emoji: "📍",
                content: String(localized: "userGuide.item.locationReminders.content")
            )
        ]
    )

    static let insightsAndStats = GuideSection(
        title: String(localized: "userGuide.section.insights"),
        icon: "chart.bar.fill",
        color: .blue,
        items: [
            GuideItem(
                title: String(localized: "userGuide.item.progressTrend.title"),
                subtitle: String(localized: "userGuide.item.progressTrend.subtitle"),
                emoji: "📈",
                content: String(localized: "userGuide.item.progressTrend.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.habitPatterns.title"),
                subtitle: String(localized: "userGuide.item.habitPatterns.subtitle"),
                emoji: "📊",
                content: String(localized: "userGuide.item.habitPatterns.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.heatmap.title"),
                subtitle: String(localized: "userGuide.item.heatmap.subtitle"),
                emoji: "🗓️",
                content: String(localized: "userGuide.item.heatmap.content")
            )
        ]
    )

    static let tipsAndTricks = GuideSection(
        title: String(localized: "userGuide.section.tips"),
        icon: "lightbulb.fill",
        color: .purple,
        items: [
            GuideItem(
                title: String(localized: "userGuide.item.startSmall.title"),
                subtitle: String(localized: "userGuide.item.startSmall.subtitle"),
                emoji: "🌱",
                content: String(localized: "userGuide.item.startSmall.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.habitStacking.title"),
                subtitle: String(localized: "userGuide.item.habitStacking.subtitle"),
                emoji: "🧱",
                content: String(localized: "userGuide.item.habitStacking.content")
            ),
            GuideItem(
                title: String(localized: "userGuide.item.twoMinRule.title"),
                subtitle: String(localized: "userGuide.item.twoMinRule.subtitle"),
                emoji: "⏱️",
                content: String(localized: "userGuide.item.twoMinRule.content")
            )
        ]
    )
}

struct GuideItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let emoji: String?
    let content: String

    init(title: String, subtitle: String? = nil, emoji: String? = nil, content: String) {
        self.title = title
        self.subtitle = subtitle
        self.emoji = emoji
        self.content = content
    }
}

#Preview {
    NavigationStack {
        UserGuideView()
    }
}
