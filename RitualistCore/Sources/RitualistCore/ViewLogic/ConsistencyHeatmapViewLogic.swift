//
//  ConsistencyHeatmapViewLogic.swift
//  RitualistCore
//
//  View logic for consistency heatmap display calculations.
//  Provides color mapping and grid data transformation for GitHub-style heatmaps.
//

import SwiftUI
import Foundation

/// View logic for consistency heatmap visualization
public enum ConsistencyHeatmapViewLogic {

    // MARK: - Layout Constants

    public enum LayoutConstants {
        /// Cell size (square) for heatmap cells
        public static let cellSize: CGFloat = 12
        /// Gap between cells
        public static let cellGap: CGFloat = 3
        /// Number of rows (days of week)
        public static let rowCount: Int = 7
        /// Corner radius for cells
        public static let cellCornerRadius: CGFloat = 2
    }

    // MARK: - Color Constants

    private enum ColorConstants {
        /// Opacity for empty cells (0% completion)
        static let emptyOpacity: Double = 0.15
        /// Base opacity for completed cells (minimum visible green)
        static let baseOpacity: Double = 0.25
        /// Additional opacity range that scales with completion rate
        static let opacityRange: Double = 0.75
    }

    // MARK: - Cell Data

    /// Data for a single cell in the heatmap grid
    public struct CellData: Identifiable, Sendable {
        public let id: String
        public let date: Date
        public let completionRate: Double
        public let dayOfWeek: Int  // 1 = Sunday, 2 = Monday, etc. (Calendar convention)
        public let weekIndex: Int  // 0-based week column index

        public init(id: String, date: Date, completionRate: Double, dayOfWeek: Int, weekIndex: Int) {
            self.id = id
            self.date = date
            self.completionRate = completionRate
            self.dayOfWeek = dayOfWeek
            self.weekIndex = weekIndex
        }
    }

    // MARK: - Color Logic

    /// Computes the fill color based on completion rate (0.0 to 1.0)
    /// Uses a green gradient intensity - darker green = higher completion
    public static func colorForCompletion(_ rate: Double) -> Color {
        // Defensive clamping to handle any out-of-bounds values
        let clampedRate = max(0, min(1, rate))

        if clampedRate <= 0 {
            // No completion - very light gray
            return Color.gray.opacity(ColorConstants.emptyOpacity)
        }

        // Green with intensity based on completion rate
        let opacity = ColorConstants.baseOpacity + (clampedRate * ColorConstants.opacityRange)
        return Color.green.opacity(opacity)
    }

    // MARK: - Grid Data Transformation

    /// Transforms daily completion data into a grid structure for rendering
    /// - Parameters:
    ///   - dailyCompletions: Dictionary of date → completion rate
    ///   - period: The time period being displayed
    ///   - timezone: Timezone for date calculations
    /// - Returns: 2D array of CellData organized by [weekIndex][dayOfWeek]
    public static func buildGridData(
        from dailyCompletions: [Date: Double],
        period: TimePeriod,
        timezone: TimeZone
    ) -> [[CellData]] {
        // Use cached calendar for performance in hot paths
        var calendar = CalendarUtils.cachedCalendar(for: timezone)
        // Start week on Monday
        calendar.firstWeekday = 2

        let dateRange = period.dateRange
        let startDate = CalendarUtils.startOfDayLocal(for: dateRange.start, timezone: timezone)
        let endDate = CalendarUtils.startOfDayLocal(for: dateRange.end, timezone: timezone)

        // Find the Monday of the start week
        let startWeekday = calendar.component(.weekday, from: startDate)
        // Convert to Monday-based (Mon=0, Tue=1, ..., Sun=6)
        let mondayOffset = (startWeekday + 5) % 7
        let firstMonday = CalendarUtils.addDaysLocal(-mondayOffset, to: startDate, timezone: timezone)

        // Build cells
        var cells: [CellData] = []
        var currentDate = firstMonday
        var weekIndex = 0

        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            // Convert to row index (Mon=0, Tue=1, ..., Sun=6)
            let rowIndex = (weekday + 5) % 7

            // Look up completion for this date
            let dayStart = CalendarUtils.startOfDayLocal(for: currentDate, timezone: timezone)
            let completionRate = dailyCompletions[dayStart] ?? 0.0

            // Only include dates within our period
            if currentDate >= startDate {
                let cell = CellData(
                    id: "\(weekIndex)-\(rowIndex)",
                    date: currentDate,
                    completionRate: completionRate,
                    dayOfWeek: rowIndex,
                    weekIndex: weekIndex
                )
                cells.append(cell)
            }

            // Move to next day
            currentDate = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: timezone)

            // If we've moved to Monday, increment week index
            let newWeekday = calendar.component(.weekday, from: currentDate)
            if newWeekday == 2 {  // Monday
                weekIndex += 1
            }
        }

        // Organize into grid: array of arrays where outer index is week, inner is day
        var grid: [[CellData]] = []
        let maxWeekIndex = cells.map { $0.weekIndex }.max() ?? 0

        for week in 0...maxWeekIndex {
            var weekCells: [CellData] = []
            for day in 0..<7 {
                if let cell = cells.first(where: { $0.weekIndex == week && $0.dayOfWeek == day }) {
                    weekCells.append(cell)
                }
            }
            if !weekCells.isEmpty {
                grid.append(weekCells)
            }
        }

        return grid
    }

    /// Returns the abbreviated day names for row labels (Mon, Tue, etc.)
    /// Optionally show only certain rows to save space
    public static func dayLabels(showAll: Bool = false) -> [(index: Int, label: String)] {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        if showAll {
            return days.enumerated().map { (index: $0.offset, label: $0.element) }
        }
        // Show only Mon, Wed, Fri for compact display
        return [(0, "Mon"), (2, "Wed"), (4, "Fri")]
    }

    /// Calculates the total width needed for the heatmap
    public static func totalWidth(for weekCount: Int) -> CGFloat {
        CGFloat(weekCount) * (LayoutConstants.cellSize + LayoutConstants.cellGap) - LayoutConstants.cellGap
    }

    /// Calculates the total height needed for the heatmap
    public static func totalHeight() -> CGFloat {
        CGFloat(LayoutConstants.rowCount) * (LayoutConstants.cellSize + LayoutConstants.cellGap) - LayoutConstants.cellGap
    }
}
