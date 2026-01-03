import Testing
@testable import RitualistCore

/// Tests for StreaksLayoutViewLogic - demonstrates testable layout calculation pattern
@Suite("StreaksLayoutViewLogic Tests")
@MainActor
struct StreaksLayoutViewLogicTests {

    // MARK: - Number of Rows Tests

    @Test("Number of rows for 0 items")
    func numberOfRowsZeroItems() {
        let rows = StreaksLayoutViewLogic.numberOfRows(for: 0)
        #expect(rows == 1, "Empty state should still reserve 1 row")
    }

    @Test("Number of rows for 1 item")
    func numberOfRowsOneItem() {
        let rows = StreaksLayoutViewLogic.numberOfRows(for: 1)
        #expect(rows == 1, "Single item should use 1 row")
    }

    @Test("Number of rows for 2 items")
    func numberOfRowsTwoItems() {
        let rows = StreaksLayoutViewLogic.numberOfRows(for: 2)
        #expect(rows == 1, "Two items should use 1 row")
    }

    @Test("Number of rows for 3 items")
    func numberOfRowsThreeItems() {
        let rows = StreaksLayoutViewLogic.numberOfRows(for: 3)
        #expect(rows == 2, "Three items should trigger 2 rows")
    }

    @Test("Number of rows for 5 items")
    func numberOfRowsFiveItems() {
        let rows = StreaksLayoutViewLogic.numberOfRows(for: 5)
        #expect(rows == 2, "Five items should use 2 rows")
    }

    @Test("Number of rows for 10 items")
    func numberOfRowsTenItems() {
        let rows = StreaksLayoutViewLogic.numberOfRows(for: 10)
        #expect(rows == 2, "Large number of items should cap at 2 rows")
    }

    // MARK: - Grid Height Tests

    @Test("Grid height for 0 items (single row)")
    func gridHeightZeroItems() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 0,
            itemHeight: 100,
            rowSpacing: 12
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 100, "Empty state should be single row height")
    }

    @Test("Grid height for 1 item (single row)")
    func gridHeightOneItem() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 1,
            itemHeight: 100,
            rowSpacing: 12
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 100, "Single item should be 100 (1 row)")
    }

    @Test("Grid height for 2 items (single row)")
    func gridHeightTwoItems() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 2,
            itemHeight: 100,
            rowSpacing: 12
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 100, "Two items should be 100 (1 row)")
    }

    @Test("Grid height for 3 items (two rows)")
    func gridHeightThreeItems() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 3,
            itemHeight: 100,
            rowSpacing: 12
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 212, "Three items should be 212 (2×100 + 12 spacing)")
    }

    @Test("Grid height for 5 items (two rows)")
    func gridHeightFiveItems() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 5,
            itemHeight: 100,
            rowSpacing: 12
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 212, "Five items should be 212 (2×100 + 12 spacing)")
    }

    @Test("Grid height with custom dimensions")
    func gridHeightCustomDimensions() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 4,
            itemHeight: 80,
            rowSpacing: 16
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 176, "Custom dimensions: 2×80 + 16 = 176")
    }

    // MARK: - Item Distribution Tests

    @Test("Distribute 0 items returns empty array")
    func distributeZeroItems() {
        let items: [Int] = []
        let rows = StreaksLayoutViewLogic.distributeItems(items)
        #expect(rows.isEmpty, "Empty input should return empty array")
    }

    @Test("Distribute 1 item creates single row")
    func distributeOneItem() {
        let items = [1]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 1, "Should create 1 row")
        #expect(rows[0] == [1], "Row 1 should contain [1]")
    }

    @Test("Distribute 2 items creates single row")
    func distributeTwoItems() {
        let items = [1, 2]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 1, "Should create 1 row")
        #expect(rows[0] == [1, 2], "Row 1 should contain [1, 2]")
    }

    @Test("Distribute 3 items creates two rows (2+1 pattern)")
    func distributeThreeItems() {
        let items = [1, 2, 3]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 2, "Should create 2 rows")
        #expect(rows[0] == [1, 2], "Row 1 should contain [1, 2]")
        #expect(rows[1] == [3], "Row 2 should contain [3]")
    }

    @Test("Distribute 4 items creates two rows (2+2 pattern)")
    func distributeFourItems() {
        let items = [1, 2, 3, 4]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 2, "Should create 2 rows")
        #expect(rows[0] == [1, 2], "Row 1 should contain [1, 2]")
        #expect(rows[1] == [3, 4], "Row 2 should contain [3, 4]")
    }

    @Test("Distribute 5 items creates two rows (3+2 pattern)")
    func distributeFiveItems() {
        let items = [1, 2, 3, 4, 5]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 2, "Should create 2 rows")
        #expect(rows[0] == [1, 2, 3], "Row 1 should contain [1, 2, 3]")
        #expect(rows[1] == [4, 5], "Row 2 should contain [4, 5]")
    }

    @Test("Distribute 6 items creates two rows (3+3 pattern)")
    func distributeSixItems() {
        let items = [1, 2, 3, 4, 5, 6]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 2, "Should create 2 rows")
        #expect(rows[0] == [1, 2, 3], "Row 1 should contain [1, 2, 3]")
        #expect(rows[1] == [4, 5, 6], "Row 2 should contain [4, 5, 6]")
    }

    @Test("Distribute 7 items creates two rows (4+3 pattern)")
    func distributeSevenItems() {
        let items = [1, 2, 3, 4, 5, 6, 7]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 2, "Should create 2 rows")
        #expect(rows[0] == [1, 2, 3, 4], "Row 1 should contain [1, 2, 3, 4]")
        #expect(rows[1] == [5, 6, 7], "Row 2 should contain [5, 6, 7]")
    }

    // MARK: - Generic Type Tests

    @Test("Distribute works with strings")
    func distributeStrings() {
        let items = ["A", "B", "C"]
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 2)
        #expect(rows[0] == ["A", "B"])
        #expect(rows[1] == ["C"])
    }

    @Test("Distribute works with custom types")
    func distributeCustomTypes() {
        struct Item: Equatable {
            let id: Int
            let name: String
        }

        let items = [
            Item(id: 1, name: "First"),
            Item(id: 2, name: "Second"),
            Item(id: 3, name: "Third"),
            Item(id: 4, name: "Fourth")
        ]

        let rows = StreaksLayoutViewLogic.distributeItems(items)

        #expect(rows.count == 2)
        #expect(rows[0].count == 2)
        #expect(rows[1].count == 2)
        #expect(rows[0][0].id == 1)
        #expect(rows[1][1].id == 4)
    }

    // MARK: - Edge Case Tests

    @Test("Distribution maintains order")
    func distributionMaintainsOrder() {
        let items = Array(1...10)
        let rows = StreaksLayoutViewLogic.distributeItems(items)

        // Flatten and verify order preserved
        let flattened = rows.flatMap { $0 }
        #expect(flattened == items, "Order should be maintained across rows")
    }

    @Test("Layout context with zero spacing")
    func layoutContextZeroSpacing() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 4,
            itemHeight: 100,
            rowSpacing: 0
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 200, "Zero spacing should give 2×100 = 200")
    }

    @Test("Layout context with large spacing")
    func layoutContextLargeSpacing() {
        let context = StreaksLayoutViewLogic.LayoutContext(
            itemCount: 3,
            itemHeight: 100,
            rowSpacing: 50
        )

        let height = StreaksLayoutViewLogic.gridHeight(for: context)
        #expect(height == 250, "Large spacing should give 2×100 + 50 = 250")
    }

    // MARK: - Single Row Layout Tests

    @Test("Single row layout on iPhone with 0 items")
    func singleRowLayoutiPhoneZeroItems() {
        let result = StreaksLayoutViewLogic.useSingleRowLayout(isCompactWidth: true, itemCount: 0)
        #expect(result == true, "iPhone with 0 items should use single row")
    }

    @Test("Single row layout on iPhone with 1 item")
    func singleRowLayoutiPhoneOneItem() {
        let result = StreaksLayoutViewLogic.useSingleRowLayout(isCompactWidth: true, itemCount: 1)
        #expect(result == true, "iPhone with 1 item should use single row")
    }

    @Test("Single row layout on iPhone with 2 items")
    func singleRowLayoutiPhoneTwoItems() {
        let result = StreaksLayoutViewLogic.useSingleRowLayout(isCompactWidth: true, itemCount: 2)
        #expect(result == true, "iPhone with 2 items should use single row")
    }

    @Test("Single row layout on iPhone with 3 items")
    func singleRowLayoutiPhoneThreeItems() {
        let result = StreaksLayoutViewLogic.useSingleRowLayout(isCompactWidth: true, itemCount: 3)
        #expect(result == false, "iPhone with 3+ items should NOT use single row")
    }

    @Test("Single row layout on iPad with 1 item")
    func singleRowLayoutiPadOneItem() {
        let result = StreaksLayoutViewLogic.useSingleRowLayout(isCompactWidth: false, itemCount: 1)
        #expect(result == true, "iPad with 1 item should use single row layout")
    }

    @Test("Single row layout on iPad with 2 items")
    func singleRowLayoutiPadTwoItems() {
        let result = StreaksLayoutViewLogic.useSingleRowLayout(isCompactWidth: false, itemCount: 2)
        #expect(result == true, "iPad with 2 items should use single row layout")
    }

    @Test("Single row layout on iPad with 3 items")
    func singleRowLayoutiPadThreeItems() {
        let result = StreaksLayoutViewLogic.useSingleRowLayout(isCompactWidth: false, itemCount: 3)
        #expect(result == false, "iPad with 3+ items should NOT use single row layout")
    }
}
