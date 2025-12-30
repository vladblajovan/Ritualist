//
//  HabitsEmptyStateView.swift
//  Ritualist
//

import SwiftUI
import RitualistCore

struct HabitsEmptyStateView: View {
    let selectedFilterCategory: HabitCategory?
    let categories: [HabitCategory]
    let isOverFreeLimit: Bool
    let habitCount: Int
    let maxHabits: Int
    let onCategoryTap: (HabitCategory?) -> Void
    let onManageTap: () -> Void
    let onUpgradeTap: () -> Void
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Over-limit banner
                if isOverFreeLimit {
                    HabitLimitBannerView(
                        currentCount: habitCount,
                        maxCount: maxHabits,
                        onUpgradeTap: onUpgradeTap
                    )
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                }

                if selectedFilterCategory != nil {
                    CategoryCarouselWithManagement(
                        categories: categories,
                        selectedCategory: selectedFilterCategory,
                        onCategoryTap: onCategoryTap,
                        onManageTap: onManageTap,
                        scrollToStartOnSelection: true,
                        allowDeselection: true,
                        unselectedBackgroundColor: Color(.secondarySystemGroupedBackground)
                    )
                    .padding(.top, Spacing.small)
                    .padding(.bottom, Spacing.medium)
                }

                VStack(spacing: Spacing.xlarge) {
                    if selectedFilterCategory != nil {
                        ContentUnavailableView(
                            "No habits in this category",
                            systemImage: "tray",
                            description: Text("No habits found for the selected category. Try selecting a different category or create a new habit.")
                        )
                    } else {
                        HabitsFirstTimeEmptyState()
                    }
                }
                .padding(.top, Spacing.large)
            }
        }
        .contentMargins(.horizontal, 4, for: .scrollContent)
        .refreshable {
            await onRefresh()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct HabitsFirstTimeEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(Strings.EmptyState.noHabitsYet)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text("Tap")
                    Image(systemName: "plus")
                        .fontWeight(.medium)
                    Text("or")
                    Image(systemName: "sparkles")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("to create your first habit")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No habits yet. Tap plus or the AI assistant button to create your first habit.")
    }
}
