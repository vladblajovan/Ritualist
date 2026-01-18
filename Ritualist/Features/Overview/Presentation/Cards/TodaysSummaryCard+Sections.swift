//
//  TodaysSummaryCard+Sections.swift
//  Ritualist
//
//  Section content methods extracted from TodaysSummaryCard to reduce type body length.
//

import SwiftUI
import RitualistCore
import TipKit

// MARK: - Habits Section Methods

extension TodaysSummaryCard {

    /// Grid columns for iPad layout
    var iPadGrid: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: BusinessConstants.iPadHabitGridColumns)
    }

    @ViewBuilder
    func habitsSection(summary: TodaysSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            remainingHabitsSection(summary: summary)
            completedHabitsSection(summary: summary)
        }
    }

    @ViewBuilder
    func remainingHabitsSection(summary: TodaysSummary) -> some View {
        if !visibleIncompleteHabits.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                remainingSectionHeader(count: visibleIncompleteHabits.count)
                if isRemainingViewCompact {
                    compactRemainingCircles(habits: visibleIncompleteHabits).padding(.horizontal, 6)
                } else if horizontalSizeClass == .regular {
                    LazyVGrid(columns: iPadGrid, spacing: 8) {
                        ForEach(visibleIncompleteHabits, id: \.id) { habit in habitRow(habit: habit, isCompleted: false) }
                    }
                } else {
                    incompleteHabitsContent(summary: summary)
                }
            }
        }
    }

    @ViewBuilder
    func completedHabitsSection(summary: TodaysSummary) -> some View {
        if !summary.completedHabits.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                completedSectionHeader(count: summary.completedHabits.count)
                if isCompletedViewCompact {
                    compactCompletedCircles(habits: summary.completedHabits).padding(.horizontal, 6)
                } else if horizontalSizeClass == .regular {
                    LazyVGrid(columns: iPadGrid, spacing: 8) {
                        ForEach(summary.completedHabits, id: \.id) { habit in habitRow(habit: habit, isCompleted: true) }
                    }
                } else {
                    completedHabitsContent(summary: summary)
                }
            }
        }
    }

    @ViewBuilder
    func incompleteHabitsContent(summary: TodaysSummary) -> some View {
        if !visibleIncompleteHabits.isEmpty {
            VStack(spacing: 8) {
                ForEach(Array(visibleIncompleteHabits.enumerated()), id: \.element.id) { index, habit in
                    incompleteHabitItem(habit: habit, isFirstItem: index == 0)
                }
            }
        }
    }

    @ViewBuilder
    func incompleteHabitItem(habit: Habit, isFirstItem: Bool) -> some View {
        if isFirstItem {
            VStack(spacing: 4) {
                // Show tap tip OR long-press tip based on TipKit rules
                // Status observers donate chain events on ANY dismissal (X button or action)
                TipView(tapHabitTip, arrowEdge: .bottom)
                    .task {
                        for await status in tapHabitTip.statusUpdates {
                            if case .invalidated = status {
                                TapHabitTip.wasDismissed.sendDonation()
                                logger.log("Tap habit tip dismissed - completed habit tip enabled", level: .debug, category: .ui)
                            }
                        }
                    }
                TipView(longPressLogTip, arrowEdge: .bottom)
                    .task {
                        for await status in longPressLogTip.statusUpdates {
                            // Only donate chain events for X button dismissal (.tipClosed)
                            // For programmatic dismissal (.actionPerformed), we donate in onComplete
                            // after the habit is actually completed and moved
                            if case .invalidated(let reason) = status, reason == .tipClosed {
                                LongPressLogTip.wasDismissed.sendDonation()
                                CircleProgressTip.longPressTipDismissed.sendDonation()
                                logger.log("Long-press tip X-dismissed - circle progress tip enabled", level: .debug, category: .ui)
                            }
                        }
                    }
                habitRow(habit: habit, isCompleted: false)
            }
            .onAppear {
                logger.log("First incomplete habit row appeared - tip should show if eligible", level: .debug, category: .ui)
            }
        } else {
            habitRow(habit: habit, isCompleted: false)
        }
    }

    @ViewBuilder
    func completedHabitsContent(summary: TodaysSummary) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(summary.completedHabits.enumerated()), id: \.element.id) { index, habit in
                completedHabitItem(habit: habit, isFirstItem: index == 0)
            }
        }
    }

    @ViewBuilder
    func completedHabitItem(habit: Habit, isFirstItem: Bool) -> some View {
        if isFirstItem {
            VStack(spacing: 4) {
                // Status observer donates chain events on ANY dismissal (X button or action)
                TipView(tapCompletedHabitTip, arrowEdge: .bottom)
                    .task {
                        for await status in tapCompletedHabitTip.statusUpdates {
                            if case .invalidated = status {
                                TapCompletedHabitTip.wasDismissed.sendDonation()
                                LongPressLogTip.shouldShowLongPressTip.sendDonation()
                                logger.log("Completed habit tip dismissed - long-press tip enabled", level: .debug, category: .ui)
                            }
                        }
                    }
                habitRow(habit: habit, isCompleted: true)
            }
            .onAppear {
                logger.log("First completed habit row appeared - tip should show if eligible", level: .debug, category: .ui)
            }
        } else {
            habitRow(habit: habit, isCompleted: true)
        }
    }
}

// MARK: - Loading and Empty State Views

extension TodaysSummaryCard {

    @ViewBuilder
    var loadingView: some View {
        // Loading progress bar placeholder
        RoundedRectangle(cornerRadius: 4)
            .fill(CardDesign.secondaryBackground)
            .frame(height: 8)
            .redacted(reason: .placeholder)
            .accessibilityLabel(Strings.Accessibility.loadingHabits)
    }

    @ViewBuilder
    var noHabitsScheduledView: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.6))
                .accessibilityHidden(true) // Decorative icon

            Text(Strings.EmptyState.noHabitsScheduled)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            Button {
                showingNoHabitsInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(Strings.Accessibility.noHabitsInfoButton)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Accessibility.noHabitsScheduledAccessibility)
        .sheet(isPresented: $showingNoHabitsInfoSheet) {
            NoHabitsScheduledInfoSheet()
        }
    }
}
