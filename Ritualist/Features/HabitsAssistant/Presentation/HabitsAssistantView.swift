//
//  HabitsAssistantView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation
import SwiftUI
import RitualistCore

/// Presentation component for displaying habit suggestions.
/// Uses HabitsAssistantSheetViewModel for all state and logic.
public struct HabitsAssistantView: View {
    @Bindable var vm: HabitsAssistantSheetViewModel

    let isFirstVisit: Bool
    let onSuggestionTap: (HabitSuggestion, Bool) async -> Void
    let onShowPaywall: () -> Void

    // MARK: - Local UI State

    @State private var isCreatingHabit = false
    @State private var isDeletingHabit = false

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Show enhanced intro section only on first visit (post-onboarding)
                if isFirstVisit {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                            Text(Strings.HabitsAssistant.firstVisitTitle)
                                .font(.title3)
                                .fontWeight(.bold)

                            Text(Strings.HabitsAssistant.firstVisitDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        #if !ALL_FEATURES_ENABLED
                        HabitLimitBannerView(
                            currentCount: vm.projectedHabitCount,
                            maxCount: vm.maxHabitsAllowed,
                            onUpgradeTap: onShowPaywall
                        )
                        #endif
                    }
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.medium)
                    .padding(.bottom, Spacing.small)
                }

                // Regular limit banner (shown when at/over limit on subsequent visits)
                if !isFirstVisit && vm.shouldShowLimitBanner {
                    HabitLimitBannerView(
                        currentCount: vm.projectedHabitCount,
                        maxCount: vm.maxHabitsAllowed,
                        onUpgradeTap: onShowPaywall
                    )
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.medium)
                    .padding(.bottom, Spacing.small)
                }

                // Category selector
                CategoryCarouselWithManagement(
                    categories: vm.categories,
                    selectedCategory: $vm.selectedCategory,
                    onManageTap: nil,
                    scrollToStartOnSelection: false,
                    allowDeselection: true,
                    unselectedBackgroundColor: Color(.secondarySystemGroupedBackground)
                )
                .padding(.top, Spacing.small)
                .padding(.bottom, Spacing.small)

                // Habit suggestions
                LazyVStack(spacing: Spacing.medium) {
                    ForEach(vm.getSuggestions()) { suggestion in
                        HabitSuggestionRow(
                            suggestion: suggestion,
                            isAdded: vm.addedSuggestionIds.contains(suggestion.id),
                            isCreating: isCreatingHabit,
                            isDeleting: isDeletingHabit,
                            onAdd: {
                                isCreatingHabit = true
                                await onSuggestionTap(suggestion, true)
                                isCreatingHabit = false
                            },
                            onRemove: {
                                isDeletingHabit = true
                                await onSuggestionTap(suggestion, false)
                                isDeletingHabit = false
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.top, Spacing.medium)
                .padding(.bottom, Spacing.xlarge)
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await vm.loadCategories()
        }
    }
}

private struct HabitSuggestionRow: View {
    let suggestion: HabitSuggestion
    let isAdded: Bool
    let isCreating: Bool
    let isDeleting: Bool
    let onAdd: () async -> Void
    let onRemove: () async -> Void

    private var scheduleText: String {
        switch suggestion.schedule {
        case .daily:
            return "Daily"
        case .daysOfWeek(let days):
            let dayNames = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let selectedDays = days.sorted().compactMap { day in
                day <= dayNames.count - 1 ? dayNames[day] : nil
            }
            return selectedDays.joined(separator: ", ")
        }
    }

    private var targetText: String? {
        guard let target = suggestion.dailyTarget,
              let unit = suggestion.unitLabel else { return nil }
        return "\(Int(target)) \(unit)"
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Emoji and color indicator
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 50, height: 50)

                Text(suggestion.emoji)
                    .font(.title2)
            }

            // Habit info
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                Text(suggestion.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: Spacing.small) {
                    Text(scheduleText)
                        .font(.caption)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 2)
                        .background(.gray.opacity(0.1), in: Capsule())

                    if let target = targetText {
                        Text(target)
                            .font(.caption)
                            .padding(.horizontal, Spacing.small)
                            .padding(.vertical, 2)
                            .background(.gray.opacity(0.1), in: Capsule())
                    }
                }
            }

            Spacer()

            // Add/Remove indicator
            ZStack {
                Circle()
                    .fill(isAdded ? Color.green : AppColors.brand)
                    .frame(width: 32, height: 32)

                if (isCreating && !isAdded) || (isDeleting && isAdded) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .transition(.scale.combined(with: .opacity))
                } else if isAdded {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAdded)
            .animation(.easeInOut(duration: 0.2), value: isCreating)
            .animation(.easeInOut(duration: 0.2), value: isDeleting)
        }
        .padding(Spacing.medium)
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: CardDesign.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isCreating && !isDeleting else { return }
            Task {
                if isAdded {
                    await onRemove()
                } else {
                    await onAdd()
                }
            }
        }
    }
}
