//
//  ConsistencyHeatmapCard.swift
//  Ritualist
//
//  A premium stats card showing a GitHub-style consistency heatmap
//  for a selected habit over the chosen time period.
//

import SwiftUI
import RitualistCore

struct ConsistencyHeatmapCard: View {
    let habits: [Habit]
    let selectedHabit: Habit?
    let gridData: [[ConsistencyHeatmapViewLogic.CellData]]
    let isLoading: Bool
    let timezone: TimeZone
    let onHabitSelected: (Habit) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header with title
            headerView

            // Habit picker
            habitPicker

            // Heatmap content with explicit state handling
            heatmapContent
        }
        .padding(CardDesign.cardPadding)
        .background(CardDesign.cardBackground)
        .cornerRadius(CardDesign.cornerRadius)
    }

    @ViewBuilder
    private var heatmapContent: some View {
        if habits.isEmpty {
            emptyStateView
        } else if isLoading {
            loadingView
        } else if !gridData.isEmpty {
            HeatmapGridView(gridData: gridData, timezone: timezone)
        } else {
            // Fallback: no data and not loading (unlikely but defensive)
            loadingView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(Strings.Stats.consistencyHeatmap)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            // Optional info button could go here
        }
    }

    // MARK: - Habit Picker

    private var habitPicker: some View {
        Menu {
            ForEach(habits) { habit in
                Button {
                    onHabitSelected(habit)
                } label: {
                    // Combine emoji + name in single Text for native Menu rendering
                    Text("\(habit.emoji ?? "📊") \(habit.name)")
                }
            }
        } label: {
            HStack {
                if let habit = selectedHabit {
                    Text(habit.emoji ?? "📊")
                        .accessibilityHidden(true)
                    Text(habit.name)
                        .lineLimit(1)
                } else {
                    Text(Strings.Stats.selectHabit)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xsmall)
            .background(CardDesign.secondaryBackground)
            .cornerRadius(CardDesign.innerCornerRadius)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(habitPickerAccessibilityLabel)
        .accessibilityHint(Strings.Stats.selectHabit)
    }

    private var habitPickerAccessibilityLabel: String {
        if let habit = selectedHabit {
            return habit.name
        }
        return Strings.Stats.selectHabit
    }

    // MARK: - States

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(height: 120)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(Strings.Stats.noHabitsForHeatmap)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}
