//
//  OverviewView+Sections.swift
//  Ritualist
//
//  Content section builders extracted from OverviewView to reduce type body length.
//

import SwiftUI
import RitualistCore

// MARK: - Content Sections

extension OverviewView {

    // MARK: - Today's Summary Section

    @ViewBuilder
    var todaysSummarySection: some View {
        TodaysSummaryCard(
            summary: vm.todaysSummary,
            viewingDate: vm.viewingDate,
            isViewingToday: vm.isViewingToday,
            timezone: vm.displayTimezone,
            canGoToPrevious: vm.canGoToPreviousDay,
            canGoToNext: vm.canGoToNextDay,
            weeklyData: vm.monthlyCompletionData,
            currentSlogan: vm.isViewingToday ? vm.currentSlogan : nil,
            onQuickAction: { habit in
                Task { @MainActor in
                    await vm.completeHabit(habit)
                }
            },
            onNumericHabitUpdate: { habit, newValue in
                try await vm.updateNumericHabit(habit, value: newValue)
            },
            getProgressSync: { habit in
                vm.getProgressSync(for: habit)
            },
            onNumericHabitAction: { habit in
                vm.showNumericSheet(for: habit)
            },
            onBinaryHabitAction: { habit in
                vm.showBinarySheet(for: habit)
            },
            onLongPressComplete: { habit in
                Task { @MainActor in
                    if habit.kind == .binary {
                        await vm.completeHabit(habit)
                    } else {
                        let targetValue = habit.dailyTarget ?? 1.0
                        try? await vm.updateNumericHabit(habit, value: targetValue)
                    }
                }
            },
            onDeleteHabitLog: { habit in
                Task { @MainActor in
                    await vm.deleteHabitLog(habit)
                }
            },
            getScheduleStatus: { habit in
                vm.getScheduleStatus(for: habit)
            },
            getValidationMessage: { habit in
                await vm.getScheduleValidationMessage(for: habit)
            },
            getStreakStatus: { habit in
                vm.getStreakStatusSync(for: habit)
            },
            onPreviousDay: {
                vm.goToPreviousDay()
            },
            onNextDay: {
                vm.goToNextDay()
            },
            onGoToToday: {
                vm.goToToday()
            },
            onDateSelected: { date in
                vm.goToDate(date)
            },
            isLoggingLocked: vm.showDeactivateHabitsBanner
        )
        .cardStyle()
    }

    // MARK: - Calendar Section

    @ViewBuilder
    func calendarSection(proxy: ScrollViewProxy) -> some View {
        // Note: Removed `|| vm.isLoading` condition to prevent layout flash.
        // StreaksCard handles its own loading state internally with a ProgressView.
        if vm.shouldShowActiveStreaks {
            calendarWithStreaks(proxy: proxy)
        } else {
            calendarOnly(proxy: proxy)
        }
    }

    @ViewBuilder
    func calendarWithStreaks(proxy: ScrollViewProxy) -> some View {
        EqualHeightRow {
            StreaksCard(
                streaks: vm.activeStreaks,
                shouldAnimateBestStreak: false,
                onAnimationComplete: {}
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .cardStyle()
        } second: {
            MonthlyCalendarCard(
                monthlyData: vm.monthlyCompletionData,
                onDateSelect: { date in
                    vm.goToDate(date)
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo("scrollTop", anchor: .top)
                        }
                    }
                },
                timezone: vm.displayTimezone,
                selectedDate: vm.viewingDate
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .cardStyle()
        }
    }

    @ViewBuilder
    func calendarOnly(proxy: ScrollViewProxy) -> some View {
        MonthlyCalendarCard(
            monthlyData: vm.monthlyCompletionData,
            onDateSelect: { date in
                vm.goToDate(date)
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo("scrollTop", anchor: .top)
                    }
                }
            },
            timezone: vm.displayTimezone,
            selectedDate: vm.viewingDate
        )
        .cardStyle()
    }

    // MARK: - Personality Section

    @ViewBuilder
    var personalitySection: some View {
        if vm.shouldShowPersonalityInsights {
            PersonalityInsightsCard(
                insights: vm.personalityInsights,
                dominantTrait: vm.dominantPersonalityTrait,
                isDataSufficient: vm.isPersonalityDataSufficient,
                thresholdRequirements: vm.personalityThresholdRequirements,
                onOpenAnalysis: {
                    vm.openPersonalityAnalysis()
                }
            )
            .cardStyle()
        } else if vm.showPersonalityUpsell {
            PersonalityInsightsUpsellCard(
                onUnlock: {
                    vm.showPersonalityPaywall()
                }
            )
            .cardStyle()
        }
    }
}
