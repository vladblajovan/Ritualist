import Foundation

/// View logic for streaks card layout calculations
/// Separated for testability and reusability across the app
public enum StreaksLayoutViewLogic {

    /// Context containing all layout configuration parameters
    public struct LayoutContext {
        public let itemCount: Int
        public let itemHeight: CGFloat
        public let rowSpacing: CGFloat

        public init(itemCount: Int, itemHeight: CGFloat, rowSpacing: CGFloat) {
            self.itemCount = itemCount
            self.itemHeight = itemHeight
            self.rowSpacing = rowSpacing
        }
    }

    // MARK: - Row Calculation

    /// Calculates the number of rows needed based on item count
    /// - Parameter itemCount: Number of items to display
    /// - Returns: Number of rows (1 for 0-2 items, 2 for 3+ items)
    public static func numberOfRows(for itemCount: Int) -> Int {
        if itemCount == 0 { return 1 }
        return itemCount <= 2 ? 1 : 2
    }

    // MARK: - Layout Mode

    /// Determines whether to use single row layout.
    /// ≤2 streaks always use single row for optimal horizontal space usage on any device.
    /// - Parameters:
    ///   - isCompactWidth: Whether the device is in compact width class (iPhone) - not used, kept for API compatibility
    ///   - itemCount: Number of items to display
    /// - Returns: true if single row layout should be used
    public static func useSingleRowLayout(isCompactWidth: Bool, itemCount: Int) -> Bool {
        itemCount <= 2
    }

    // MARK: - Height Calculation

    /// Calculates the total grid height based on layout context
    /// - Parameter context: Layout context with item count and dimensions
    /// - Returns: Total height needed for the grid
    /// - Formula: (numberOfRows × itemHeight) + ((numberOfRows - 1) × rowSpacing)
    public static func gridHeight(for context: LayoutContext) -> CGFloat {
        let rows = numberOfRows(for: context.itemCount)
        let baseHeight = CGFloat(rows) * context.itemHeight
        let spacingHeight = rows > 1 ? CGFloat(rows - 1) * context.rowSpacing : 0
        return baseHeight + spacingHeight
    }

    // MARK: - Item Distribution

    /// Distributes items into rows using horizontal-first filling pattern
    /// - Parameter items: Array of items to distribute
    /// - Returns: 2D array where each inner array represents a row
    ///
    /// Distribution pattern:
    /// - 0 items: Empty array
    /// - 1-2 items: Single row with all items
    /// - 3+ items: Two rows, first row gets ceil(count/2), second row gets floor(count/2)
    ///
    /// Examples:
    /// - 1 item: [[1]]
    /// - 2 items: [[1, 2]]
    /// - 3 items: [[1, 2], [3]]
    /// - 4 items: [[1, 2], [3, 4]]
    /// - 5 items: [[1, 2, 3], [4, 5]]
    public static func distributeItems<T>(_ items: [T]) -> [[T]] {
        guard !items.isEmpty else { return [] }

        let rows = numberOfRows(for: items.count)

        if rows == 1 {
            // Single row: all items
            return [Array(items)]
        } else {
            // Two rows: distribute evenly
            // First row gets ceil(count/2), second row gets floor(count/2)
            let midpoint = (items.count + 1) / 2
            let row1 = Array(items.prefix(midpoint))
            let row2 = Array(items.dropFirst(midpoint))
            return [row1, row2]
        }
    }
}
