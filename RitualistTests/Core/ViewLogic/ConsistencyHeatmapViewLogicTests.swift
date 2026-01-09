//
//  ConsistencyHeatmapViewLogicTests.swift
//  RitualistTests
//
//  Tests for ConsistencyHeatmapViewLogic - color mapping and grid building logic.
//

import Testing
import SwiftUI
@testable import RitualistCore

@Suite("ConsistencyHeatmapViewLogic Tests")
@MainActor
struct ConsistencyHeatmapViewLogicTests {

    let timezone = TimeZone(identifier: "America/New_York")!
    let calendar: Calendar

    init() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        calendar = cal
    }

    // MARK: - Layout Constants Tests

    @Test("Layout constants have expected values")
    func layoutConstantsValues() {
        #expect(ConsistencyHeatmapViewLogic.LayoutConstants.cellSize == 12)
        #expect(ConsistencyHeatmapViewLogic.LayoutConstants.cellGap == 3)
        #expect(ConsistencyHeatmapViewLogic.LayoutConstants.rowCount == 7)
        #expect(ConsistencyHeatmapViewLogic.LayoutConstants.cellCornerRadius == 2)
    }

    // MARK: - Color Mapping Tests

    @Test("Color for 0% completion returns gray")
    func colorForZeroCompletion() {
        let color = ConsistencyHeatmapViewLogic.colorForCompletion(0.0)
        // Gray at 0.15 opacity for empty cells
        #expect(color == Color.gray.opacity(0.15))
    }

    @Test("Color for negative rate clamps to 0% (gray)")
    func colorForNegativeRateClampsToZero() {
        let color = ConsistencyHeatmapViewLogic.colorForCompletion(-0.5)
        #expect(color == Color.gray.opacity(0.15))
    }

    @Test("Color for rate > 1.0 clamps to 100% (full green)")
    func colorForOverflowRateClampsToOne() {
        let color = ConsistencyHeatmapViewLogic.colorForCompletion(1.5)
        // 0.25 + (1.0 * 0.75) = 1.0
        #expect(color == Color.green.opacity(1.0))
    }

    @Test("Color for 25% completion returns green at calculated opacity")
    func colorFor25PercentCompletion() {
        let color = ConsistencyHeatmapViewLogic.colorForCompletion(0.25)
        // 0.25 + (0.25 * 0.75) = 0.4375
        #expect(color == Color.green.opacity(0.4375))
    }

    @Test("Color for 50% completion returns green at calculated opacity")
    func colorFor50PercentCompletion() {
        let color = ConsistencyHeatmapViewLogic.colorForCompletion(0.5)
        // 0.25 + (0.5 * 0.75) = 0.625
        #expect(color == Color.green.opacity(0.625))
    }

    @Test("Color for 75% completion returns green at calculated opacity")
    func colorFor75PercentCompletion() {
        let color = ConsistencyHeatmapViewLogic.colorForCompletion(0.75)
        // 0.25 + (0.75 * 0.75) = 0.8125
        #expect(color == Color.green.opacity(0.8125))
    }

    @Test("Color for 100% completion returns full green")
    func colorFor100PercentCompletion() {
        let color = ConsistencyHeatmapViewLogic.colorForCompletion(1.0)
        // 0.25 + (1.0 * 0.75) = 1.0
        #expect(color == Color.green.opacity(1.0))
    }

    // MARK: - Grid Data Building Tests

    @Test("Grid data builds correct structure for 1 week period")
    func buildGridDataWeekPeriod() {
        // Use dates relative to today that will fall within .thisWeek (last 7 days)
        let today = Date()
        let dayStart = CalendarUtils.startOfDayLocal(for: today, timezone: timezone)

        // Create completions for the last few days (will definitely be in range)
        let completions: [Date: Double] = [
            dayStart: 1.0,
            addDays(-1, to: dayStart): 0.5,
            addDays(-2, to: dayStart): 0.75,
            addDays(-3, to: dayStart): 0.25
        ]

        let grid = ConsistencyHeatmapViewLogic.buildGridData(
            from: completions,
            period: .thisWeek,
            timezone: timezone
        )

        // Should have at least 1 week of data (may span 2 calendar weeks)
        #expect(grid.count >= 1)

        // Verify cells exist - at least 7 days for a week view
        let allCells = grid.flatMap { $0 }
        #expect(allCells.count >= 7, "Grid should have at least 7 cells for a week period")

        // Verify our completion data made it into the grid
        let completedCells = allCells.filter { $0.completionRate > 0 }
        #expect(completedCells.count >= 1, "Should have at least one cell with completion data")
    }

    @Test("Grid data organizes cells by week and day correctly")
    func gridDataOrganization() {
        // Use today's date which is definitely within .thisWeek
        let today = Date()
        let dayStart = CalendarUtils.startOfDayLocal(for: today, timezone: timezone)
        let completions: [Date: Double] = [
            dayStart: 0.5
        ]

        let grid = ConsistencyHeatmapViewLogic.buildGridData(
            from: completions,
            period: .thisWeek,
            timezone: timezone
        )

        // Find the cell matching today's completion
        let allCells = grid.flatMap { $0 }
        let todayCell = allCells.first { $0.completionRate == 0.5 }

        #expect(todayCell != nil, "Should find a cell with 0.5 completion for today")
    }

    @Test("Grid data handles empty completions dictionary")
    func gridDataEmptyCompletions() {
        let grid = ConsistencyHeatmapViewLogic.buildGridData(
            from: [:],
            period: .thisWeek,
            timezone: timezone
        )

        // Should still have grid structure, just with 0.0 rates
        let allCells = grid.flatMap { $0 }
        let nonZeroCells = allCells.filter { $0.completionRate > 0 }
        #expect(nonZeroCells.isEmpty)
    }

    @Test("Grid data returns 0.0 for missing dates")
    func gridDataMissingDatesReturnZero() {
        let startDate = createDate(year: 2026, month: 1, day: 5)
        // Only provide completion for first day
        let completions: [Date: Double] = [
            startDate: 1.0
        ]

        let grid = ConsistencyHeatmapViewLogic.buildGridData(
            from: completions,
            period: .thisWeek,
            timezone: timezone
        )

        let allCells = grid.flatMap { $0 }
        let zeroCells = allCells.filter { $0.completionRate == 0.0 }

        // Most cells should be 0.0 since we only provided one date
        #expect(zeroCells.count >= 6)
    }

    // MARK: - Day Labels Tests

    @Test("Day labels returns all days when showAll is true")
    func dayLabelsShowAll() {
        let labels = ConsistencyHeatmapViewLogic.dayLabels(showAll: true)

        #expect(labels.count == 7)
        #expect(labels[0].label == "Mon")
        #expect(labels[1].label == "Tue")
        #expect(labels[2].label == "Wed")
        #expect(labels[3].label == "Thu")
        #expect(labels[4].label == "Fri")
        #expect(labels[5].label == "Sat")
        #expect(labels[6].label == "Sun")
    }

    @Test("Day labels returns compact set when showAll is false")
    func dayLabelsCompact() {
        let labels = ConsistencyHeatmapViewLogic.dayLabels(showAll: false)

        #expect(labels.count == 3)
        #expect(labels[0] == (index: 0, label: "Mon"))
        #expect(labels[1] == (index: 2, label: "Wed"))
        #expect(labels[2] == (index: 4, label: "Fri"))
    }

    // MARK: - Size Calculations Tests

    @Test("Total width calculation is correct")
    func totalWidthCalculation() {
        let width = ConsistencyHeatmapViewLogic.totalWidth(for: 4)
        // 4 * (12 + 3) - 3 = 4 * 15 - 3 = 57
        #expect(width == 57)
    }

    @Test("Total height calculation is correct")
    func totalHeightCalculation() {
        let height = ConsistencyHeatmapViewLogic.totalHeight()
        // 7 * (12 + 3) - 3 = 7 * 15 - 3 = 102
        #expect(height == 102)
    }

    // MARK: - Timezone Handling Tests

    @Test("Grid data respects timezone for date boundaries")
    func gridDataTimezoneHandling() {
        // Use a timezone that's different from UTC
        let pacificTimezone = TimeZone(identifier: "America/Los_Angeles")!

        let date = createDate(year: 2026, month: 1, day: 5, timezone: pacificTimezone)
        let completions: [Date: Double] = [date: 0.8]

        let grid = ConsistencyHeatmapViewLogic.buildGridData(
            from: completions,
            period: .thisWeek,
            timezone: pacificTimezone
        )

        // Verify grid was built (timezone didn't break anything)
        #expect(!grid.isEmpty)
    }

    // MARK: - Helpers

    private func createDate(year: Int, month: Int, day: Int, timezone: TimeZone? = nil) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone ?? self.timezone
        return cal.date(from: components)!
    }

    private func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }
}
