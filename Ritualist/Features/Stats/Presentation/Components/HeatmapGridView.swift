//
//  HeatmapGridView.swift
//  Ritualist
//
//  A GitHub-style heatmap grid showing habit completion patterns.
//  Rows represent days of the week, columns represent weeks.
//

import SwiftUI
import RitualistCore

/// A scrollable heatmap grid visualization
struct HeatmapGridView: View {
    let gridData: [[ConsistencyHeatmapViewLogic.CellData]]
    let timezone: TimeZone

    private let cellSize = ConsistencyHeatmapViewLogic.LayoutConstants.cellSize
    private let cellGap = ConsistencyHeatmapViewLogic.LayoutConstants.cellGap
    private let cornerRadius = ConsistencyHeatmapViewLogic.LayoutConstants.cellCornerRadius

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Heatmap grid with day labels
            HStack(alignment: .top, spacing: Spacing.small) {
                // Day labels column
                dayLabelsColumn

                // Scrollable grid
                ScrollView(.horizontal, showsIndicators: false) {
                    heatmapGrid
                }
            }

            // Legend
            legendView
                .padding(.top, Spacing.small)
        }
    }

    // MARK: - Day Labels

    private var dayLabelsColumn: some View {
        VStack(alignment: .trailing, spacing: cellGap) {
            ForEach(0..<7, id: \.self) { dayIndex in
                Text(dayLabel(for: dayIndex))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(height: cellSize)
            }
        }
        .frame(width: 24)
    }

    private func dayLabel(for index: Int) -> String {
        // Index 0 = Monday, 6 = Sunday (2-letter abbreviations for clarity)
        let labels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        return labels[index]
    }

    // MARK: - Heatmap Grid

    private var heatmapGrid: some View {
        HStack(alignment: .top, spacing: cellGap) {
            ForEach(Array(gridData.enumerated()), id: \.offset) { _, weekCells in
                VStack(spacing: cellGap) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let cell = weekCells.first(where: { $0.dayOfWeek == dayIndex }) {
                            cellView(for: cell)
                        } else {
                            // Empty placeholder for missing days
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.clear)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .padding(.trailing, Spacing.small)
    }

    private func cellView(for cell: ConsistencyHeatmapViewLogic.CellData) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(ConsistencyHeatmapViewLogic.colorForCompletion(cell.completionRate))
            .frame(width: cellSize, height: cellSize)
            .accessibilityLabel(accessibilityLabel(for: cell))
    }

    private func accessibilityLabel(for cell: ConsistencyHeatmapViewLogic.CellData) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = timezone
        let dateString = formatter.string(from: cell.date)
        let percentage = Int(cell.completionRate * 100)
        return "\(dateString), \(percentage)% complete"
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: Spacing.small) {
            Text(Strings.Stats.heatmapLessLabel)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            HStack(spacing: 2) {
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { rate in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ConsistencyHeatmapViewLogic.colorForCompletion(rate))
                        .frame(width: 10, height: 10)
                }
            }

            Text(Strings.Stats.heatmapMoreLabel)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
