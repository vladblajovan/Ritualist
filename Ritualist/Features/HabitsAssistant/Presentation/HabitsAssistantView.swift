//
//  HabitsAssistantView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation
import SwiftUI
import RitualistCore

public struct HabitsAssistantView: View {
    @Bindable var vm: HabitsAssistantViewModel
    @State private var isCreatingHabit = false
    @State private var isDeletingHabit = false

    private let existingHabits: [Habit]
    private let onHabitCreate: (HabitSuggestion) async -> CreateHabitFromSuggestionResult
    private let onHabitRemove: (UUID) async -> Bool
    private let onShowPaywall: () -> Void
    private let shouldShowLimitBanner: Bool
    private let maxHabitsAllowed: Int
    private let getCurrentHabitCount: () -> Int

    public init(vm: HabitsAssistantViewModel,
                existingHabits: [Habit] = [],
                shouldShowLimitBanner: Bool = false,
                maxHabitsAllowed: Int = BusinessConstants.freeMaxHabits,
                getCurrentHabitCount: @escaping () -> Int = { 0 },
                onHabitCreate: @escaping (HabitSuggestion) async -> CreateHabitFromSuggestionResult,
                onHabitRemove: @escaping (UUID) async -> Bool,
                onShowPaywall: @escaping () -> Void) {
        self.vm = vm
        self.existingHabits = existingHabits
        self.shouldShowLimitBanner = shouldShowLimitBanner
        self.maxHabitsAllowed = maxHabitsAllowed
        self.getCurrentHabitCount = getCurrentHabitCount
        self.onHabitCreate = onHabitCreate
        self.onHabitRemove = onHabitRemove
        self.onShowPaywall = onShowPaywall
    }
    
    private var suggestions: [HabitSuggestion] {
        vm.getSuggestions()
    }

    private var totalHabitCount: Int {
        // Use the closure provided by the parent to get the current/projected count
        // This allows the parent (HabitsAssistantSheet) to track user intentions
        getCurrentHabitCount()
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Habit limit banner for free users
            if shouldShowLimitBanner {
                HabitLimitBannerView(
                    currentCount: totalHabitCount,
                    maxCount: maxHabitsAllowed,
                    onUpgradeTap: onShowPaywall
                )
                .padding(.horizontal, Spacing.medium)
                .padding(.top, Spacing.medium)
                .padding(.bottom, Spacing.small)
            }

            // Sticky category selector at top
            if vm.isLoadingCategories {
                ProgressView("Loading categories...")
                    .padding(.vertical, Spacing.medium)
            } else {
                VStack(spacing: Spacing.small) {
                    HorizontalCarousel(
                        items: vm.categories,
                        selectedItem: vm.selectedCategory,
                        onItemTap: { category in
                            if vm.selectedCategory?.id == category.id {
                                // Deselect if tapping the same category
                                vm.clearCategorySelection()
                            } else {
                                vm.selectCategory(category)
                            }
                        },
                        showPageIndicator: false,
                        content: { category, isSelected in
                            Chip(
                                text: category.displayName,
                                emoji: category.emoji,
                                isSelected: isSelected
                            )
                        }
                    )
                }
                .padding(.bottom, Spacing.small)
            }
            
            // Scrollable content
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    ForEach(suggestions) { suggestion in
                        HabitSuggestionRow(
                            suggestion: suggestion,
                            isAdded: vm.addedSuggestionIds.contains(suggestion.id),
                            isCreating: isCreatingHabit,
                            isDeleting: isDeletingHabit,
                            onAdd: {
                                await addHabit(suggestion)
                            },
                            onRemove: {
                                await removeHabit(suggestion)
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.top, Spacing.medium)
                .padding(.bottom, Spacing.xlarge)
            }
        }
        .background(Color.clear)
        .task {
            await vm.loadCategories()
            vm.initializeWithExistingHabits(existingHabits)
        }
    }
    
    private func addHabit(_ suggestion: HabitSuggestion) async {
        guard !vm.addedSuggestionIds.contains(suggestion.id) else { return }
        
        // Track habit suggestion viewed when user attempts to add it
        vm.trackHabitSuggestionViewed(
            habitId: suggestion.id,
            category: suggestion.categoryId
        )
        
        isCreatingHabit = true
        let result = await onHabitCreate(suggestion)
        
        switch result {
        case .success(let habitId):
            vm.markSuggestionAsAdded(suggestion.id, habitId: habitId)
            vm.trackHabitAdded(
                habitId: suggestion.id,
                habitName: suggestion.name,
                category: suggestion.categoryId
            )
        case .limitReached:
            // Show paywall for limit reached
            vm.trackHabitAddFailed(
                habitId: suggestion.id,
                error: "Habit limit reached"
            )
            onShowPaywall()
        case .error(let errorMessage):
            vm.trackHabitAddFailed(
                habitId: suggestion.id,
                error: errorMessage
            )
        }
        
        isCreatingHabit = false
    }
    
    private func removeHabit(_ suggestion: HabitSuggestion) async {
        guard vm.addedSuggestionIds.contains(suggestion.id),
              let habitId = vm.suggestionToHabitMappings[suggestion.id] else { return }
        
        isDeletingHabit = true
        let success = await onHabitRemove(habitId)
        
        if success {
            vm.markSuggestionAsRemoved(suggestion.id)
            vm.trackHabitRemoved(
                habitId: suggestion.id,
                habitName: suggestion.name,
                category: suggestion.categoryId
            )
        } else {
            vm.trackHabitRemoveFailed(
                habitId: suggestion.id,
                error: "Failed to remove habit"
            )
        }

        isDeletingHabit = false
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
            let selectedDays = days.compactMap { day in
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
            
            // Add/Remove button
            Button(action: {
                Task { 
                    if isAdded {
                        await onRemove()
                    } else {
                        await onAdd()
                    }
                }
            }, label: {
                ZStack {
                    Circle()
                        .fill(isAdded ? Color.green : AppColors.brand)
                        .frame(width: 32, height: 32)
                    
                    if (isCreating && !isAdded) || (isDeleting && isAdded) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if isAdded {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            })
            .disabled(isCreating || isDeleting)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(Spacing.medium)
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

