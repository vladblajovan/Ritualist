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
    let onAddHabit: (HabitSuggestion) async -> Void
    let onRemoveHabit: (String) async -> Void
    let onShowPaywall: () -> Void

    // MARK: - Local UI State

    /// Track which suggestion is currently being processed (by suggestionId)
    @State private var processingAddSuggestionId: String?
    @State private var processingRemoveSuggestionId: String?

    /// Search text for filtering habit suggestions
    @State private var searchText = ""

    /// Preserves category selection when searching, restores when search is cleared
    @State private var categoryBeforeSearch: HabitCategory?

    /// Filtered suggestions based on search text and selected category
    private var filteredSuggestions: [HabitSuggestion] {
        let suggestions = vm.getSuggestions()
        guard !searchText.isEmpty else { return suggestions }

        return suggestions.filter { suggestion in
            suggestion.name.localizedCaseInsensitiveContains(searchText) ||
            suggestion.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Show enhanced intro section only on first visit (post-onboarding)
                if isFirstVisit && searchText.isEmpty {
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
                if !isFirstVisit && vm.shouldShowLimitBanner && searchText.isEmpty {
                    HabitLimitBannerView(
                        currentCount: vm.projectedHabitCount,
                        maxCount: vm.maxHabitsAllowed,
                        onUpgradeTap: onShowPaywall
                    )
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.medium)
                    .padding(.bottom, Spacing.small)
                }

                // Category selector (hidden when searching)
                if searchText.isEmpty {
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
                }

                // Habit suggestions
                if filteredSuggestions.isEmpty && !searchText.isEmpty {
                    // Empty search results
                    VStack(spacing: Spacing.medium) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(Strings.HabitsAssistant.noSearchResults)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(Strings.HabitsAssistant.tryDifferentKeywords)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xxxlarge)
                    .padding(.horizontal, Spacing.xlarge)
                } else {
                    LazyVStack(spacing: Spacing.medium) {
                        ForEach(filteredSuggestions) { suggestion in
                            let isAdded = vm.addedSuggestionIds.contains(suggestion.id)
                            let isProcessingAdd = processingAddSuggestionId == suggestion.id
                            let isProcessingRemove = processingRemoveSuggestionId == suggestion.id

                            HabitSuggestionRow(
                                suggestion: suggestion,
                                isAdded: isAdded,
                                isProcessing: isProcessingAdd || isProcessingRemove,
                                onTap: {
                                    // Check current state at tap time from ViewModel
                                    let currentlyAdded = vm.addedSuggestionIds.contains(suggestion.id)

                                    if currentlyAdded {
                                        // Remove habit
                                        processingRemoveSuggestionId = suggestion.id
                                        await onRemoveHabit(suggestion.id)
                                        processingRemoveSuggestionId = nil
                                    } else {
                                        // Add habit
                                        processingAddSuggestionId = suggestion.id
                                        await onAddHabit(suggestion)
                                        processingAddSuggestionId = nil
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.medium)
                    .padding(.bottom, Spacing.xlarge)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: Strings.HabitsAssistant.searchPlaceholder)
        .onChange(of: searchText) { _, newValue in
            // Preserve category when searching, restore when search is cleared
            if !newValue.isEmpty && vm.selectedCategory != nil {
                categoryBeforeSearch = vm.selectedCategory
                vm.selectedCategory = nil
            } else if newValue.isEmpty && categoryBeforeSearch != nil {
                vm.selectedCategory = categoryBeforeSearch
                categoryBeforeSearch = nil
            }
        }
        .task {
            await vm.loadCategories()
        }
    }
}

private struct HabitSuggestionRow: View {
    let suggestion: HabitSuggestion
    let isAdded: Bool
    let isProcessing: Bool
    let onTap: () async -> Void

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

                if isProcessing {
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
            .animation(.easeInOut(duration: 0.2), value: isProcessing)
        }
        .padding(Spacing.medium)
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: CardDesign.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isProcessing else { return }
            Task {
                await onTap()
            }
        }
    }
}
