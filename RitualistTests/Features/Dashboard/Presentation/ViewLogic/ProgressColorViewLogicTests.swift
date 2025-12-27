import Testing
import SwiftUI
@testable import RitualistCore

/// Tests for ProgressColorViewLogic - demonstrates testable progress color pattern
@Suite("ProgressColorViewLogic Tests")
@MainActor
struct ProgressColorViewLogicTests {

    // MARK: - High Completion Tests (80-100%) - Green

    @Test("High completion at exactly 80% returns green")
    func highCompletion80() {
        let color = ProgressColorViewLogic.color(for: 0.8)
        #expect(color == .green, "80% is the threshold for green")
    }

    @Test("High completion at 85% returns green")
    func highCompletion85() {
        let color = ProgressColorViewLogic.color(for: 0.85)
        #expect(color == .green)
    }

    @Test("High completion at 90% returns green")
    func highCompletion90() {
        let color = ProgressColorViewLogic.color(for: 0.9)
        #expect(color == .green)
    }

    @Test("High completion at 95% returns green")
    func highCompletion95() {
        let color = ProgressColorViewLogic.color(for: 0.95)
        #expect(color == .green)
    }

    @Test("Perfect completion at 100% returns green")
    func perfectCompletion() {
        let color = ProgressColorViewLogic.color(for: 1.0)
        #expect(color == .green)
    }

    // MARK: - Medium Completion Tests (50-79%) - Orange

    @Test("Medium completion at exactly 50% returns orange")
    func mediumCompletion50() {
        let color = ProgressColorViewLogic.color(for: 0.5)
        #expect(color == .orange, "50% is the threshold for orange")
    }

    @Test("Medium completion at 55% returns orange")
    func mediumCompletion55() {
        let color = ProgressColorViewLogic.color(for: 0.55)
        #expect(color == .orange)
    }

    @Test("Medium completion at 65% returns orange")
    func mediumCompletion65() {
        let color = ProgressColorViewLogic.color(for: 0.65)
        #expect(color == .orange)
    }

    @Test("Medium completion at 75% returns orange")
    func mediumCompletion75() {
        let color = ProgressColorViewLogic.color(for: 0.75)
        #expect(color == .orange)
    }

    @Test("Medium completion at 79% returns orange")
    func mediumCompletion79() {
        let color = ProgressColorViewLogic.color(for: 0.79)
        #expect(color == .orange, "Just below 80% should still be orange")
    }

    // MARK: - Low Completion Tests (0-49%) - Red

    @Test("Low completion at 0% returns red")
    func lowCompletionZero() {
        let color = ProgressColorViewLogic.color(for: 0.0)
        #expect(color == .red)
    }

    @Test("Low completion at 10% returns red")
    func lowCompletion10() {
        let color = ProgressColorViewLogic.color(for: 0.1)
        #expect(color == .red)
    }

    @Test("Low completion at 25% returns red")
    func lowCompletion25() {
        let color = ProgressColorViewLogic.color(for: 0.25)
        #expect(color == .red)
    }

    @Test("Low completion at 49% returns red")
    func lowCompletion49() {
        let color = ProgressColorViewLogic.color(for: 0.49)
        #expect(color == .red, "Just below 50% should be red")
    }

    // MARK: - Boundary Tests

    @Test("Exact 50% boundary returns orange (inclusive)")
    func exact50Boundary() {
        let color = ProgressColorViewLogic.color(for: 0.5)
        #expect(color == .orange, "50% exactly should be orange")
    }

    @Test("Just below 50% returns red")
    func justBelow50() {
        let color = ProgressColorViewLogic.color(for: 0.499)
        #expect(color == .red, "49.9% should be red")
    }

    @Test("Exact 80% boundary returns green (inclusive)")
    func exact80Boundary() {
        let color = ProgressColorViewLogic.color(for: 0.8)
        #expect(color == .green, "80% exactly should be green")
    }

    @Test("Just below 80% returns orange")
    func justBelow80() {
        let color = ProgressColorViewLogic.color(for: 0.799)
        #expect(color == .orange, "79.9% should be orange")
    }

    @Test("Exact 100% boundary returns green")
    func exact100Boundary() {
        let color = ProgressColorViewLogic.color(for: 1.0)
        #expect(color == .green)
    }

    // MARK: - Edge Cases

    @Test("Negative completion percentage returns red")
    func negativeCompletion() {
        let color = ProgressColorViewLogic.color(for: -0.1)
        #expect(color == .red, "Negative values should default to red")
    }

    @Test("Over 100% completion returns green")
    func over100Completion() {
        let color = ProgressColorViewLogic.color(for: 1.5)
        #expect(color == .green, "Values over 100% should still be green")
    }

    @Test("Very small positive value returns red")
    func verySmallPositive() {
        let color = ProgressColorViewLogic.color(for: 0.001)
        #expect(color == .red)
    }

    @Test("Very close to 100% returns green")
    func veryCloseTo100() {
        let color = ProgressColorViewLogic.color(for: 0.999)
        #expect(color == .green)
    }

    // MARK: - CardDesign Color Variant Tests

    @Test("CardDesign color for 100% completion")
    func cardDesignColor100() {
        let color = ProgressColorViewLogic.cardDesignColor(for: 1.0)
        #expect(color == CardDesign.progressGreen, "Perfect completion uses CardDesign green")
    }

    @Test("CardDesign color for high completion (85%)")
    func cardDesignColorHigh() {
        let color = ProgressColorViewLogic.cardDesignColor(for: 0.85)
        #expect(color == CardDesign.progressOrange, "High completion uses CardDesign orange")
    }

    @Test("CardDesign color for medium completion (60%)")
    func cardDesignColorMedium() {
        let color = ProgressColorViewLogic.cardDesignColor(for: 0.6)
        #expect(color == CardDesign.progressRed.opacity(0.6), "Medium completion uses CardDesign red with opacity")
    }

    @Test("CardDesign color for low completion (20%)")
    func cardDesignColorLow() {
        let color = ProgressColorViewLogic.cardDesignColor(for: 0.2)
        #expect(color == CardDesign.secondaryBackground, "Low completion uses secondary background")
    }

    @Test("CardDesign color for zero completion")
    func cardDesignColorZero() {
        let color = ProgressColorViewLogic.cardDesignColor(for: 0.0)
        #expect(color == CardDesign.secondaryBackground, "Zero completion uses secondary background")
    }

    // MARK: - Threshold Constants Tests

    @Test("High completion threshold is 80%")
    func highCompletionThreshold() {
        #expect(ProgressColorViewLogic.highCompletionThreshold == 0.8)
    }

    @Test("Medium completion threshold is 50%")
    func mediumCompletionThreshold() {
        #expect(ProgressColorViewLogic.mediumCompletionThreshold == 0.5)
    }

    // MARK: - Consistency Tests

    @Test("Same input produces same color")
    func consistentOutput() {
        let color1 = ProgressColorViewLogic.color(for: 0.75)
        let color2 = ProgressColorViewLogic.color(for: 0.75)
        #expect(color1 == color2, "Same input should produce same color")
    }

    @Test("Incrementing through boundaries produces expected sequence")
    func boundarySequence() {
        // Below 50%
        #expect(ProgressColorViewLogic.color(for: 0.49) == .red)

        // At 50%
        #expect(ProgressColorViewLogic.color(for: 0.5) == .orange)

        // Between 50-80%
        #expect(ProgressColorViewLogic.color(for: 0.79) == .orange)

        // At 80%
        #expect(ProgressColorViewLogic.color(for: 0.8) == .green)

        // Above 80%
        #expect(ProgressColorViewLogic.color(for: 1.0) == .green)
    }
}
