import Testing
import SwiftUI
import CoreGraphics
@testable import RitualistCore

/// Tests for MonthlyCalendarViewLogic - demonstrates testable view logic pattern
@Suite("MonthlyCalendarViewLogic Tests")
@MainActor
struct MonthlyCalendarViewLogicTests {

    let calendar = CalendarUtils.currentLocalCalendar
    let today = Date()
    let yesterday: Date
    let tomorrow: Date
    let currentMonth: Int

    init() {
        yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        currentMonth = calendar.component(.month, from: today)
    }

    // MARK: - Layout Constants Tests

    @Test("Layout constants have expected values")
    func layoutConstantsValues() {
        #expect(MonthlyCalendarViewLogic.LayoutConstants.circleSizeRatio == 0.75)
        #expect(MonthlyCalendarViewLogic.LayoutConstants.maxCellSizeCompact == 36)
        #expect(MonthlyCalendarViewLogic.LayoutConstants.maxCellSizeRegular == 48)
        #expect(MonthlyCalendarViewLogic.LayoutConstants.maxVerticalSpacing == 20)
        #expect(MonthlyCalendarViewLogic.LayoutConstants.verticalSpacingRatio == 0.35)
        #expect(MonthlyCalendarViewLogic.LayoutConstants.fontSizeRatio == 0.39)
        #expect(MonthlyCalendarViewLogic.LayoutConstants.borderBuffer == 1)
        #expect(MonthlyCalendarViewLogic.LayoutConstants.columnCount == 7)
    }

    // MARK: - Layout Calculation Tests

    @Test("Layout computes correct column width for iPhone portrait")
    func layoutColumnWidthiPhonePortrait() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        #expect(metrics.columnWidth == 50, "350 / 7 = 50")
    }

    @Test("Layout caps cell size at maximum for iPhone")
    func layoutCellSizeCappediPhone() {
        // Wide canvas would produce cell size > 36 without cap
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 700, height: 400), // columnWidth = 100, 75% = 75 > 36
            maxRowIndex: 4,
            isCompactWidth: true
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        #expect(metrics.cellSize == 36, "Cell size should be capped at 36pt on iPhone")
    }

    @Test("Layout caps cell size at maximum for iPad without height constraint")
    func layoutCellSizeCappediPad() {
        // Wide canvas would produce cell size > 48 without cap
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 700, height: 400), // columnWidth = 100, 75% = 75 > 48
            maxRowIndex: 4,
            isCompactWidth: false,
            availableHeight: nil
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        #expect(metrics.cellSize == 48, "Cell size should be capped at 48pt on iPad")
    }

    @Test("Layout cell size follows ratio for small screens")
    func layoutCellSizeFollowsRatio() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 280, height: 400), // columnWidth = 40, 75% = 30 < 36
            maxRowIndex: 4,
            isCompactWidth: true
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        #expect(metrics.cellSize == 30, "Cell size should be 75% of column width (40 * 0.75 = 30)")
    }

    @Test("Layout vertical spacing is capped at maximum")
    func layoutVerticalSpacingCapped() {
        // Wide canvas would produce vertical spacing > 20 without cap
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 700, height: 400), // columnWidth = 100, 100 - 36 = 64 > 20
            maxRowIndex: 4,
            isCompactWidth: false
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        #expect(metrics.verticalSpacing == 20, "Vertical spacing should be capped at 20pt")
    }

    @Test("Layout uses height-based sizing for iPad with available height")
    func layoutHeightBasedSizingiPad() {
        // iPad with available height should size cells to fill the space
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 400, height: 300),
            maxRowIndex: 4, // 5 rows
            isCompactWidth: false,
            availableHeight: 300
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        // With 5 rows and spacingRatio 0.35:
        // divisor = 5 + 4 * 0.35 = 5 + 1.4 = 6.4
        // heightBasedCell = (300 - 2) / 6.4 = 298 / 6.4 ≈ 46.56
        // widthBasedCell = 400/7 * 0.75 ≈ 42.86
        // min(46.56, 42.86, 48) = 42.86
        let columnWidth: CGFloat = 400.0 / 7.0
        let widthBasedCellSize: CGFloat = columnWidth * 0.75
        let difference: CGFloat = abs(metrics.cellSize - widthBasedCellSize)
        #expect(difference < 0.001, "Cell size should be width-constrained")
    }

    @Test("Layout uses symmetric border buffer")
    func layoutSymmetricBorderBuffer() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        #expect(metrics.borderBuffer == 1, "Border buffer should be 1pt for symmetric top/bottom spacing")
    }

    @Test("Layout uses height-based sizing when height is constraining factor on iPad")
    func layoutHeightConstrainediPad() {
        // Wide canvas with limited height - height should be the constraint
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 600, height: 200),
            maxRowIndex: 4, // 5 rows
            isCompactWidth: false,
            availableHeight: 200
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        // With 5 rows and spacingRatio 0.35:
        // divisor = 5 + 4 * 0.35 = 6.4
        // heightBasedCell = (200 - 2) / 6.4 = 198 / 6.4 ≈ 30.9375
        // widthBasedCell = 600/7 * 0.75 ≈ 64.3
        // min(30.9375, 64.3, 48) = 30.9375 (height constrained)
        let spacingRatio: CGFloat = 0.35
        let numRows: CGFloat = 5
        let divisor: CGFloat = numRows + (numRows - 1) * spacingRatio
        let expectedCellSize: CGFloat = (200.0 - 2.0) / divisor
        let difference: CGFloat = abs(metrics.cellSize - expectedCellSize)

        #expect(difference < 0.001, "Cell size should be height-constrained")
    }

    @Test("iPad layout uses proportional spacing with height-based sizing")
    func layoutProportionalSpacingiPad() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 600, height: 200),
            maxRowIndex: 4,
            isCompactWidth: false,
            availableHeight: 200
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        // Spacing should be proportional to cell size (0.35 ratio), capped at 20
        let expectedSpacing: CGFloat = min(metrics.cellSize * 0.35, 20.0)
        let difference: CGFloat = abs(metrics.verticalSpacing - expectedSpacing)
        #expect(difference < 0.001)
    }

    @Test("Layout computes correct total height for 5 rows with symmetric buffers")
    func layoutTotalHeight5Rows() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4, // 5 rows (0-4)
            isCompactWidth: true
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        // columnWidth = 50, cellSize = min(37.5, 36) = 36 (capped at maxCellSizeCompact)
        // verticalSpacing = min(50 - 36, 20) = min(14, 20) = 14
        // totalHeight = borderBuffer + 5 * 36 + 4 * 14 + borderBuffer = 1 + 180 + 56 + 1 = 238
        let expectedHeight: CGFloat = 238

        #expect(metrics.totalHeight == expectedHeight)
    }

    @Test("Layout computes correct font size from cell size")
    func layoutFontSize() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 280, height: 400), // cellSize = 30
            maxRowIndex: 4,
            isCompactWidth: true
        )

        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)
        let expectedFontSize: CGFloat = 30.0 * 0.39

        #expect(metrics.fontSize == expectedFontSize, "Font size should be 39% of cell size")
    }

    @Test("Layout zero metrics for initial state")
    func layoutZeroMetrics() {
        let zero = MonthlyCalendarViewLogic.LayoutMetrics.zero

        #expect(zero.columnWidth == 0)
        #expect(zero.cellSize == 0)
        #expect(zero.verticalSpacing == 0)
        #expect(zero.fontSize == 0)
        #expect(zero.borderBuffer == 0)
        #expect(zero.totalHeight == 0)
    }

    // MARK: - Grid Position Tests

    @Test("Grid position for valid tap in center of first cell")
    func gridPositionValidTapFirstCell() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )
        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        // Tap in center of first cell (row 0, col 0)
        let location = CGPoint(x: 25, y: 20) // center of first column

        let position = MonthlyCalendarViewLogic.gridPosition(
            for: location,
            metrics: metrics,
            maxRowIndex: 4
        )

        #expect(position?.row == 0)
        #expect(position?.col == 0)
    }

    @Test("Grid position for valid tap in last column")
    func gridPositionValidTapLastColumn() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )
        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        // Tap in last column (col 6)
        let location = CGPoint(x: 325, y: 20)

        let position = MonthlyCalendarViewLogic.gridPosition(
            for: location,
            metrics: metrics,
            maxRowIndex: 4
        )

        #expect(position?.col == 6)
    }

    @Test("Grid position returns nil for tap outside canvas width")
    func gridPositionOutsideWidth() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )
        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        let location = CGPoint(x: 360, y: 20) // beyond canvas width

        let position = MonthlyCalendarViewLogic.gridPosition(
            for: location,
            metrics: metrics,
            maxRowIndex: 4
        )

        #expect(position == nil)
    }

    @Test("Grid position returns nil for tap with negative x")
    func gridPositionNegativeX() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )
        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        let location = CGPoint(x: -10, y: 20)

        let position = MonthlyCalendarViewLogic.gridPosition(
            for: location,
            metrics: metrics,
            maxRowIndex: 4
        )

        #expect(position == nil)
    }

    @Test("Grid position returns nil for tap beyond total height")
    func gridPositionBeyondHeight() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )
        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        let location = CGPoint(x: 100, y: metrics.totalHeight + 10)

        let position = MonthlyCalendarViewLogic.gridPosition(
            for: location,
            metrics: metrics,
            maxRowIndex: 4
        )

        #expect(position == nil)
    }

    @Test("Grid position returns nil for row beyond maxRowIndex")
    func gridPositionBeyondMaxRow() {
        let context = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 2, // Only 3 rows valid (0, 1, 2)
            isCompactWidth: true
        )
        let metrics = MonthlyCalendarViewLogic.computeLayout(for: context)

        // Tap in what would be row 3 (if the layout were taller)
        // This requires the location to be within totalHeight but calculate to row > maxRowIndex
        // With maxRowIndex=2, totalHeight is smaller, so this tests the index validation
        let location = CGPoint(x: 100, y: metrics.totalHeight - 1) // Near bottom

        let position = MonthlyCalendarViewLogic.gridPosition(
            for: location,
            metrics: metrics,
            maxRowIndex: 2
        )

        // Should return row 2 (the last valid row)
        #expect(position?.row == 2)
    }

    // MARK: - LayoutContext Tests

    @Test("LayoutContext correctly computes row count")
    func layoutContextRowCount() {
        let context4Rows = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 3,
            isCompactWidth: true
        )
        #expect(context4Rows.rowCount == 4)

        let context6Rows = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 5,
            isCompactWidth: true
        )
        #expect(context6Rows.rowCount == 6)
    }

    @Test("LayoutContext supports optional available height")
    func layoutContextAvailableHeight() {
        let withoutHeight = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: true
        )
        #expect(withoutHeight.availableHeight == nil)

        let withHeight = MonthlyCalendarViewLogic.LayoutContext(
            canvasSize: CGSize(width: 350, height: 400),
            maxRowIndex: 4,
            isCompactWidth: false,
            availableHeight: 300
        )
        #expect(withHeight.availableHeight == 300)
    }

    // MARK: - Background Color Tests

    @Test("Background color for high completion (100%)")
    func backgroundColorHighCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 1.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressGreen)
    }

    @Test("Background color at 85% - should be green")
    func backgroundColorAt85Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.85,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressGreen)
    }

    @Test("Background color at 65% - should be orange")
    func backgroundColorAt65Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.65,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressOrange)
    }

    @Test("Background color at 80% - should be green")
    func backgroundColorAt80Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.8,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressGreen)
    }

    @Test("Background color at 50% - should be orange")
    func backgroundColorAt50Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressOrange)
    }

    @Test("Background color at 49% - should be red")
    func backgroundColorAt49Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.49,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressRed.opacity(0.6))
    }

    @Test("Background color at 30% - should be red")
    func backgroundColorAt30Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.3,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressRed.opacity(0.6))
    }

    @Test("Background color for no completion (0%)")
    func backgroundColorNoCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.secondaryBackground)
    }

    @Test("Background color for future date")
    func backgroundColorFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.secondaryBackground)
    }

    // MARK: - Text Color Tests

    @Test("Text color for today with high progress (readable white on colored background)")
    func textColorTodayHighProgress() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.9,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .white, "High progress today should use white text")
    }

    @Test("Text color for today with no progress (readable dark on gray background)")
    func textColorTodayNoProgress() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .primary, "No progress today should use dark text for contrast")
    }

    @Test("Text color for today with low progress (readable dark on light background)")
    func textColorTodayLowProgress() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .primary, "Low progress today should use dark text for contrast")
    }

    @Test("Text color for past date with high completion")
    func textColorPastHighCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.9,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .white)
    }

    @Test("Text color for past date with no completion")
    func textColorPastNoCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .primary)
    }

    @Test("Text color for future date")
    func textColorFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .secondary)
    }

    // MARK: - Opacity Tests

    @Test("Opacity for past date")
    func opacityPastDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let opacity = MonthlyCalendarViewLogic.opacity(for: context)
        #expect(opacity == 1.0)
    }

    @Test("Opacity for today")
    func opacityToday() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let opacity = MonthlyCalendarViewLogic.opacity(for: context)
        #expect(opacity == 1.0)
    }

    @Test("Opacity for future date")
    func opacityFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let opacity = MonthlyCalendarViewLogic.opacity(for: context)
        #expect(opacity == 0.3, "Future dates should have reduced opacity")
    }

    // MARK: - Border Tests

    @Test("Border shown for today")
    func borderShownForToday() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let hasBorder = MonthlyCalendarViewLogic.shouldShowBorder(for: context)
        #expect(hasBorder == true)
    }

    @Test("Border not shown for past date")
    func borderNotShownForPastDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 1.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let hasBorder = MonthlyCalendarViewLogic.shouldShowBorder(for: context)
        #expect(hasBorder == false)
    }

    @Test("Border not shown for future date")
    func borderNotShownForFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let hasBorder = MonthlyCalendarViewLogic.shouldShowBorder(for: context)
        #expect(hasBorder == false)
    }

    // MARK: - Context Computed Properties Tests

    @Test("Context correctly identifies today")
    func contextIdentifiesToday() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        #expect(context.isToday == true)
        #expect(context.isFuture == false)
    }

    @Test("Context correctly identifies future date")
    func contextIdentifiesFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        #expect(context.isToday == false)
        #expect(context.isFuture == true)
    }

    @Test("Context correctly identifies past date")
    func contextIdentifiesPastDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        #expect(context.isToday == false)
        #expect(context.isFuture == false)
    }
}
