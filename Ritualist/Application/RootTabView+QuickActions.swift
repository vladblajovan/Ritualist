//
//  RootTabView+QuickActions.swift
//  Ritualist
//
//  Quick Actions handling extracted from RootTabView to reduce type body length.
//

import SwiftUI
import RitualistCore

// MARK: - Quick Action Sheet Modifiers

extension RootTabView {

    @ViewBuilder
    func quickActionAddHabitSheet() -> some View {
        let detailVM = HabitDetailViewModel(habit: nil)
        HabitDetailView(vm: detailVM)
            .accessibilityIdentifier(AccessibilityID.HabitDetail.sheet)
    }

    func handleQuickActionAddHabitDismiss() {
        Task { @MainActor in
            await loadCurrentHabits()
        }
        // Check if we need to re-show this sheet or show a different one
        if pendingQuickActionAddHabitReshow {
            pendingQuickActionAddHabitReshow = false
            logger.log("Quick Action: Re-showing Add Habit sheet after dismiss", level: .info, category: .ui)
            showingQuickActionAddHabit = true
        } else if pendingQuickActionHabitsAssistantReshow {
            pendingQuickActionHabitsAssistantReshow = false
            logger.log("Quick Action: Showing Habits Assistant sheet after Add Habit dismiss", level: .info, category: .ui)
            showingQuickActionHabitsAssistant = true
        }
    }

    func handleQuickActionHabitsAssistantRefresh() async {
        await loadCurrentHabits()
        // Check if we need to re-show this sheet or show a different one
        if pendingQuickActionHabitsAssistantReshow {
            pendingQuickActionHabitsAssistantReshow = false
            logger.log("Quick Action: Re-showing Habits Assistant sheet after dismiss", level: .info, category: .ui)
            showingQuickActionHabitsAssistant = true
        } else if pendingQuickActionAddHabitReshow {
            pendingQuickActionAddHabitReshow = false
            logger.log("Quick Action: Showing Add Habit sheet after Habits Assistant dismiss", level: .info, category: .ui)
            showingQuickActionAddHabit = true
        }
    }
}

// MARK: - Quick Action onChange Handlers

extension RootTabView {

    func handleShouldShowAddHabit(_ shouldShow: Bool) {
        if shouldShow {
            logger.log("Quick Action: Add Habit triggered - switching to habits tab", level: .info, category: .ui)
            viewModel.navigationService.selectedTab = .habits

            if showingQuickActionHabitsAssistant {
                pendingQuickActionAddHabitReshow = true
                showingQuickActionHabitsAssistant = false
            } else if showingQuickActionAddHabit {
                pendingQuickActionAddHabitReshow = true
                showingQuickActionAddHabit = false
            } else {
                logger.log("Quick Action: Showing Add Habit sheet", level: .info, category: .ui)
                showingQuickActionAddHabit = true
            }
            quickActionCoordinator.resetTriggers()
        }
    }

    func handleShouldShowHabitsAssistant(_ shouldShow: Bool) {
        if shouldShow {
            logger.log("Quick Action: Habits Assistant triggered - switching to habits tab", level: .info, category: .ui)
            viewModel.navigationService.selectedTab = .habits

            if showingQuickActionAddHabit {
                pendingQuickActionHabitsAssistantReshow = true
                showingQuickActionAddHabit = false
            } else if showingQuickActionHabitsAssistant {
                pendingQuickActionHabitsAssistantReshow = true
                showingQuickActionHabitsAssistant = false
            } else {
                logger.log("Quick Action: Showing Habits Assistant sheet", level: .info, category: .ui)
                showingQuickActionHabitsAssistant = true
            }
            quickActionCoordinator.resetTriggers()
        }
    }

    func handleShouldNavigateToStats(_ shouldShow: Bool) {
        if shouldShow {
            logger.log("Quick Action: Stats triggered - switching to stats tab", level: .info, category: .ui)
            showingQuickActionAddHabit = false
            showingQuickActionHabitsAssistant = false
            viewModel.navigationService.selectedTab = .stats
            quickActionCoordinator.resetTriggers()
        }
    }
}
