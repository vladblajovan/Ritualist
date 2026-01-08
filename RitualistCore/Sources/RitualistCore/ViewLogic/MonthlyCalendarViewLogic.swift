import SwiftUI
import Foundation
import CoreGraphics

/// View logic for monthly calendar display calculations
/// Separated for testability and reusability across the app
public enum MonthlyCalendarViewLogic {

    // MARK: - Layout Constants

    /// Named constants for calendar grid layout calculations.
    /// Centralized here for maintainability, documentation, and testability.
    public enum LayoutConstants {
        /// Circle diameter as fraction of column width.
        /// 75% provides optimal balance between touch target size and visual spacing.
        public static let circleSizeRatio: CGFloat = 0.75

        /// Maximum circle size on iPhone (compact width).
        /// 36pt ensures consistent touch targets while fitting screen constraints.
        public static let maxCellSizeCompact: CGFloat = 36

        /// Maximum circle size on iPad (regular width).
        /// 48pt provides larger touch targets and better visual weight on bigger screens.
        public static let maxCellSizeRegular: CGFloat = 48

        /// Maximum vertical spacing between rows.
        /// Capped at 20pt to prevent excessive gaps in landscape orientation.
        public static let maxVerticalSpacing: CGFloat = 20

        /// Vertical spacing as ratio of cell size for height-based calculations.
        /// 0.35 provides visually balanced spacing proportional to circle size.
        public static let verticalSpacingRatio: CGFloat = 0.35

        /// Font size as fraction of circle diameter.
        /// 0.39 maintains readability across all device sizes.
        public static let fontSizeRatio: CGFloat = 0.39

        /// Symmetric buffer for content that extends outside circle bounds.
        /// Applied to both top and bottom. Accommodates today glow (2pt) + border stroke (1pt).
        public static let borderBuffer: CGFloat = 3

        /// Number of columns in the calendar grid (days per week)
        public static let columnCount: Int = 7
    }

    // MARK: - Layout Metrics

    /// Computed layout dimensions for the calendar grid.
    /// All values are derived from canvas size and row count.
    public struct LayoutMetrics: Equatable, Sendable {
        /// Width of each day column (canvas width / 7)
        public let columnWidth: CGFloat
        /// Diameter of day circles
        public let cellSize: CGFloat
        /// Vertical gap between rows
        public let verticalSpacing: CGFloat
        /// Font size for day numbers
        public let fontSize: CGFloat
        /// Symmetric buffer for border clipping (applied to top and bottom)
        public let borderBuffer: CGFloat
        /// Total height of the calendar grid content
        public let totalHeight: CGFloat

        public init(
            columnWidth: CGFloat,
            cellSize: CGFloat,
            verticalSpacing: CGFloat,
            fontSize: CGFloat,
            borderBuffer: CGFloat,
            totalHeight: CGFloat
        ) {
            self.columnWidth = columnWidth
            self.cellSize = cellSize
            self.verticalSpacing = verticalSpacing
            self.fontSize = fontSize
            self.borderBuffer = borderBuffer
            self.totalHeight = totalHeight
        }

        /// Empty metrics for initial state
        public static let zero = LayoutMetrics(
            columnWidth: 0,
            cellSize: 0,
            verticalSpacing: 0,
            fontSize: 0,
            borderBuffer: 0,
            totalHeight: 0
        )
    }

    /// Input parameters for layout calculation
    public struct LayoutContext: Sendable {
        /// Size of the canvas/container
        public let canvasSize: CGSize
        /// Maximum row index (0-based) for current month days
        public let maxRowIndex: Int
        /// Whether the device is in compact width class (iPhone)
        public let isCompactWidth: Bool
        /// Available height for dynamic sizing (iPad EqualHeightRow scenario)
        /// When provided, cell size is calculated to optimally fill this height
        public let availableHeight: CGFloat?

        public init(canvasSize: CGSize, maxRowIndex: Int, isCompactWidth: Bool, availableHeight: CGFloat? = nil) {
            self.canvasSize = canvasSize
            self.maxRowIndex = maxRowIndex
            self.isCompactWidth = isCompactWidth
            self.availableHeight = availableHeight
        }

        /// Number of rows in the calendar grid
        public var rowCount: Int {
            maxRowIndex + 1
        }
    }

    // MARK: - Layout Calculation

    /// Computes all layout metrics from the given context.
    /// This is the single source of truth for both Canvas rendering and tap detection.
    ///
    /// **Sizing Strategy:**
    /// - iPhone (compact): Width-based sizing with maxCellSizeCompact cap
    /// - iPad (regular) with availableHeight: Height-based sizing to fill available space
    /// - iPad (regular) without availableHeight: Width-based sizing with maxCellSizeRegular cap
    ///
    /// - Parameter context: Layout context with canvas size and row information
    /// - Returns: Computed layout metrics
    public static func computeLayout(for context: LayoutContext) -> LayoutMetrics {
        let columnWidth = context.canvasSize.width / CGFloat(LayoutConstants.columnCount)
        let numRows = context.rowCount
        let borderBuffer = LayoutConstants.borderBuffer

        // Determine cell size based on device and available height
        let cellSize: CGFloat
        let verticalSpacing: CGFloat

        if let availableHeight = context.availableHeight, !context.isCompactWidth, availableHeight > 0 {
            // iPad with known available height: size to fill the space
            // Formula: height = 2*buffer + rows*cell + (rows-1)*spacing
            // With spacing = cell * spacingRatio:
            // height = 2*buffer + rows*cell + (rows-1)*cell*spacingRatio
            // height - 2*buffer = cell * (rows + (rows-1)*spacingRatio)
            // cell = (height - 2*buffer) / (rows + (rows-1)*spacingRatio)
            let spacingRatio = LayoutConstants.verticalSpacingRatio
            let divisor = CGFloat(numRows) + CGFloat(numRows - 1) * spacingRatio
            let heightBasedCellSize = (availableHeight - 2 * borderBuffer) / divisor

            // Cap at maximum and minimum reasonable sizes
            let maxCell = LayoutConstants.maxCellSizeRegular
            let widthBasedCellSize = columnWidth * LayoutConstants.circleSizeRatio
            cellSize = min(heightBasedCellSize, widthBasedCellSize, maxCell)

            // Spacing proportional to cell size
            verticalSpacing = min(cellSize * spacingRatio, LayoutConstants.maxVerticalSpacing)
        } else {
            // iPhone or iPad without height constraint: width-based sizing
            let maxCell = context.isCompactWidth ? LayoutConstants.maxCellSizeCompact : LayoutConstants.maxCellSizeRegular
            cellSize = min(columnWidth * LayoutConstants.circleSizeRatio, maxCell)
            verticalSpacing = min(columnWidth - cellSize, LayoutConstants.maxVerticalSpacing)
        }

        // Total height with symmetric top and bottom buffers
        let totalHeight = borderBuffer + CGFloat(numRows) * cellSize + CGFloat(numRows - 1) * verticalSpacing + borderBuffer

        return LayoutMetrics(
            columnWidth: columnWidth,
            cellSize: cellSize,
            verticalSpacing: verticalSpacing,
            fontSize: cellSize * LayoutConstants.fontSizeRatio,
            borderBuffer: borderBuffer,
            totalHeight: totalHeight
        )
    }

    // MARK: - Tap Detection

    /// Converts a tap location to grid coordinates.
    /// Returns nil if the tap is outside valid bounds.
    ///
    /// - Parameters:
    ///   - location: Tap location in canvas coordinate space
    ///   - metrics: Layout metrics for the current canvas
    ///   - maxRowIndex: Maximum valid row index
    /// - Returns: Tuple of (row, column) indices, or nil if out of bounds
    public static func gridPosition(
        for location: CGPoint,
        metrics: LayoutMetrics,
        maxRowIndex: Int
    ) -> (row: Int, col: Int)? {
        // Validate location is within grid bounds
        guard location.x >= 0, location.x < metrics.columnWidth * CGFloat(LayoutConstants.columnCount),
              location.y >= 0, location.y < metrics.totalHeight else {
            return nil
        }

        let col = Int(location.x / metrics.columnWidth)
        let row = Int((location.y - metrics.borderBuffer) / (metrics.cellSize + metrics.verticalSpacing))

        // Validate computed indices
        guard col >= 0, col < LayoutConstants.columnCount,
              row >= 0, row <= maxRowIndex else {
            return nil
        }

        return (row: row, col: col)
    }

    /// Context containing all information needed to compute day display properties
    public struct DayContext {
        public let date: Date
        public let completion: Double
        public let today: Date
        public let currentMonth: Int
        public let calendar: Calendar

        public init(date: Date, completion: Double, today: Date, currentMonth: Int, calendar: Calendar) {
            self.date = date
            self.completion = completion
            self.today = today
            self.currentMonth = currentMonth
            self.calendar = calendar
        }

        /// Whether this day is today (in the calendar's timezone)
        public var isToday: Bool {
            // Compare day/month/year components explicitly using the calendar's timezone
            let tz = calendar.timeZone
            let dateComponents = calendar.dateComponents(in: tz, from: date)
            let todayComponents = calendar.dateComponents(in: tz, from: Date())
            return dateComponents.year == todayComponents.year &&
                   dateComponents.month == todayComponents.month &&
                   dateComponents.day == todayComponents.day
        }

        /// Whether this day is in the future (relative to today in the calendar's timezone)
        public var isFuture: Bool {
            // Compare day/month/year components explicitly using the calendar's timezone
            let tz = calendar.timeZone
            let dateComponents = calendar.dateComponents(in: tz, from: date)
            let todayComponents = calendar.dateComponents(in: tz, from: Date())

            // Safe unwrapping - return false (not future) if any component is nil
            guard let dateYear = dateComponents.year,
                  let dateMonth = dateComponents.month,
                  let dateDay = dateComponents.day,
                  let todayYear = todayComponents.year,
                  let todayMonth = todayComponents.month,
                  let todayDay = todayComponents.day else {
                return false
            }

            if dateYear > todayYear { return true }
            if dateYear < todayYear { return false }
            if dateMonth > todayMonth { return true }
            if dateMonth < todayMonth { return false }
            return dateDay > todayDay
        }

        /// Whether this day belongs to the current viewing month
        public var isCurrentMonth: Bool {
            let tz = calendar.timeZone
            let dateMonth = calendar.dateComponents(in: tz, from: date).month
            return dateMonth == currentMonth
        }
    }

    // MARK: - Background Color Logic

    /// Computes the background color based on completion percentage and date context
    /// Matches CircularProgressView.adaptiveProgressColors thresholds
    /// - Parameter context: Day context with date and completion information
    /// - Returns: Background color for the day circle
    public static func backgroundColor(for context: DayContext) -> Color {
        // Future dates get neutral background
        if context.isFuture {
            return CardDesign.secondaryBackground
        }

        // Past/today dates get color based on completion
        // Matches gradient thresholds: 0-50% red, 50-80% orange, 80-100% green, 100% full green
        if context.completion >= 1.0 {
            return CardDesign.progressGreen
        }
        if context.completion >= 0.8 {
            return CardDesign.progressGreen
        }
        if context.completion >= 0.5 {
            return CardDesign.progressOrange
        }
        if context.completion > 0 {
            return CardDesign.progressRed.opacity(0.6)
        }

        // No progress
        return CardDesign.secondaryBackground
    }

    // MARK: - Text Color Logic

    /// Computes the text color ensuring readability based on background
    /// - Parameter context: Day context with date and completion information
    /// - Returns: Text color for the day number
    public static func textColor(for context: DayContext) -> Color {
        // Today: Use completion-aware color for proper contrast
        if context.isToday {
            // High progress (≥80%): White text on colored background
            // Low/no progress (<80%): Dark text on light gray background
            return context.completion >= 0.8 ? .white : .primary
        }

        // Future dates: Subdued appearance
        if context.isFuture {
            return .secondary
        }

        // Past dates: Match background intensity
        return context.completion >= 0.8 ? .white : .primary
    }

    // MARK: - Visual State Logic

    /// Computes the opacity for the day display
    /// - Parameter context: Day context with date information
    /// - Returns: Opacity value (0.0 to 1.0)
    public static func opacity(for context: DayContext) -> Double {
        context.isFuture ? 0.3 : 1.0
    }

    /// Determines whether to show a border around the day circle
    /// - Parameter context: Day context with date information
    /// - Returns: true if border should be shown (today indicator)
    public static func shouldShowBorder(for context: DayContext) -> Bool {
        context.isToday
    }
}
