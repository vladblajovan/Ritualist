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
    let heatmapData: ConsistencyHeatmapData?
    let selectedPeriod: TimePeriod
    let timezone: TimeZone
    let onHabitSelected: (Habit) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header with title
            headerView

            // Habit picker
            habitPicker

            // Heatmap content or placeholder
            if let data = heatmapData {
                let gridData = ConsistencyHeatmapViewLogic.buildGridData(
                    from: data.dailyCompletions,
                    period: selectedPeriod,
                    timezone: timezone
                )
                HeatmapGridView(gridData: gridData, timezone: timezone)
            } else if habits.isEmpty {
                emptyStateView
            } else {
                // Loading state (habit auto-selected, waiting for data)
                loadingView
            }
        }
        .padding(CardDesign.cardPadding)
        .background(CardDesign.cardBackground)
        .cornerRadius(CardDesign.cornerRadius)
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
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xsmall)
            .background(CardDesign.secondaryBackground)
            .cornerRadius(CardDesign.innerCornerRadius)
        }
        .buttonStyle(.plain)
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
