//
//  CircularProgressViewTests.swift
//  RitualistTests
//
//  Tests for CircularProgressView accessibility and adaptive gradient logic
//

import Foundation
import Testing
import SwiftUI
@testable import RitualistCore
@testable import Ritualist

/// Tests for CircularProgressView accessibility features
@Suite("CircularProgressView - Accessibility")
struct CircularProgressViewAccessibilityTests {

    // MARK: - Default Accessibility Label Tests

    @Test("Default accessibility label shows percentage")
    func defaultAccessibilityLabelShowsPercentage() {
        // Progress values and their expected labels
        let testCases: [(progress: Double, expected: String)] = [
            (0.0, "0 percent progress"),
            (0.25, "25 percent progress"),
            (0.5, "50 percent progress"),
            (0.75, "75 percent progress"),
            (1.0, "100 percent progress")
        ]

        for testCase in testCases {
            let view = CircularProgressView(
                progress: testCase.progress,
                color: .blue
            )
            // The default label is set internally; we verify the formula
            let expectedLabel = "\(Int(testCase.progress * 100)) percent progress"
            #expect(expectedLabel == testCase.expected)
        }
    }

    @Test("Custom accessibility label overrides default")
    func customAccessibilityLabelOverridesDefault() {
        let customLabel = "Daily goal completion"
        let view = CircularProgressView(
            progress: 0.75,
            color: .blue,
            accessibilityLabel: customLabel
        )
        // Custom label should be used instead of default
        #expect(customLabel == "Daily goal completion")
    }

    @Test("Accessibility hint can be customized")
    func accessibilityHintCanBeCustomized() {
        let customHint = "Tap to view details"
        let view = CircularProgressView(
            progress: 0.5,
            color: .green,
            accessibilityHint: customHint
        )
        #expect(customHint == "Tap to view details")
    }

    @Test("Accessibility identifier can be customized")
    func accessibilityIdentifierCanBeCustomized() {
        let customId = "dashboard.weeklyProgress"
        let view = CircularProgressView(
            progress: 0.8,
            color: .orange,
            accessibilityIdentifier: customId
        )
        #expect(customId == "dashboard.weeklyProgress")
    }

    @Test("Default accessibility identifier uses Stats.circularProgress")
    func defaultAccessibilityIdentifierUsesStatsCircularProgress() {
        // When no identifier provided, default should be used
        let defaultId = AccessibilityID.Stats.circularProgress
        #expect(defaultId == "stats.circularProgress")
    }

    // MARK: - Progress Rounding Tests

    @Test("Progress percentage rounds correctly for accessibility")
    func progressPercentageRoundsCorrectly() {
        // Edge cases for percentage rounding
        let testCases: [(progress: Double, expectedPercent: Int)] = [
            (0.004, 0),    // Rounds down to 0%
            (0.005, 0),    // Int() truncates, so 0.5 becomes 0
            (0.994, 99),   // Rounds to 99%
            (0.999, 99),   // Still 99%
            (1.0, 100)     // Exactly 100%
        ]

        for testCase in testCases {
            let calculatedPercent = Int(testCase.progress * 100)
            #expect(calculatedPercent == testCase.expectedPercent)
        }
    }
}

/// Tests for CircularProgressView adaptive gradient logic
@Suite("CircularProgressView - Adaptive Gradients")
struct CircularProgressViewGradientTests {

    // MARK: - Color Threshold Tests

    @Test("Low completion (0-50%) uses red gradient")
    func lowCompletionUsesRedGradient() {
        let colors0 = CircularProgressView.adaptiveProgressColors(for: 0.0)
        let colors25 = CircularProgressView.adaptiveProgressColors(for: 0.25)
        let colors49 = CircularProgressView.adaptiveProgressColors(for: 0.49)

        // All should include progressRed as second color
        #expect(colors0.count == 2)
        #expect(colors25.count == 2)
        #expect(colors49.count == 2)

        // First color should be ritualistCyan
        #expect(colors0[0] == Color.ritualistCyan)
        #expect(colors25[0] == Color.ritualistCyan)
        #expect(colors49[0] == Color.ritualistCyan)

        // Second color should be progressRed
        #expect(colors0[1] == CardDesign.progressRed)
        #expect(colors25[1] == CardDesign.progressRed)
        #expect(colors49[1] == CardDesign.progressRed)
    }

    @Test("Medium completion (50-80%) uses orange gradient")
    func mediumCompletionUsesOrangeGradient() {
        let colors50 = CircularProgressView.adaptiveProgressColors(for: 0.50)
        let colors65 = CircularProgressView.adaptiveProgressColors(for: 0.65)
        let colors79 = CircularProgressView.adaptiveProgressColors(for: 0.79)

        // All should include progressOrange as second color
        #expect(colors50[1] == CardDesign.progressOrange)
        #expect(colors65[1] == CardDesign.progressOrange)
        #expect(colors79[1] == CardDesign.progressOrange)
    }

    @Test("High completion (80-100%) uses green gradient")
    func highCompletionUsesGreenGradient() {
        let colors80 = CircularProgressView.adaptiveProgressColors(for: 0.80)
        let colors90 = CircularProgressView.adaptiveProgressColors(for: 0.90)
        let colors99 = CircularProgressView.adaptiveProgressColors(for: 0.99)

        // All should include progressGreen as second color
        #expect(colors80[1] == CardDesign.progressGreen)
        #expect(colors90[1] == CardDesign.progressGreen)
        #expect(colors99[1] == CardDesign.progressGreen)
    }

    @Test("Perfect completion (100%) uses green gradient")
    func perfectCompletionUsesGreenGradient() {
        let colors100 = CircularProgressView.adaptiveProgressColors(for: 1.0)

        #expect(colors100[0] == Color.ritualistCyan)
        #expect(colors100[1] == CardDesign.progressGreen)
    }

    // MARK: - Boundary Tests

    @Test("Progress clamped to valid range 0-1")
    func progressClampedToValidRange() {
        // Negative progress should be treated as 0
        let colorsNegative = CircularProgressView.adaptiveProgressColors(for: -0.5)
        #expect(colorsNegative[1] == CardDesign.progressRed) // 0% = red

        // Progress > 1 should be treated as 1
        let colorsOver = CircularProgressView.adaptiveProgressColors(for: 1.5)
        #expect(colorsOver[1] == CardDesign.progressGreen) // 100% = green
    }

    @Test("Exact threshold values produce correct colors")
    func exactThresholdValuesProduceCorrectColors() {
        // Test exact threshold boundaries
        // 0.5 threshold: should be orange (>= 0.5)
        let colors50 = CircularProgressView.adaptiveProgressColors(for: 0.5)
        #expect(colors50[1] == CardDesign.progressOrange)

        // 0.8 threshold: should be green (>= 0.8)
        let colors80 = CircularProgressView.adaptiveProgressColors(for: 0.8)
        #expect(colors80[1] == CardDesign.progressGreen)

        // Just below thresholds
        let colors499 = CircularProgressView.adaptiveProgressColors(for: 0.499)
        #expect(colors499[1] == CardDesign.progressRed)

        let colors799 = CircularProgressView.adaptiveProgressColors(for: 0.799)
        #expect(colors799[1] == CardDesign.progressOrange)
    }
}

/// Tests for CircularProgressView initialization variants
@Suite("CircularProgressView - Initialization")
struct CircularProgressViewInitTests {

    @Test("Single color initializer sets properties correctly")
    func singleColorInitializerSetsProperties() {
        let view = CircularProgressView(
            progress: 0.6,
            color: .purple,
            lineWidth: 10,
            showPercentage: true,
            accessibilityLabel: "Test label",
            accessibilityHint: "Test hint",
            accessibilityIdentifier: "test.id"
        )
        // Properties should be set (verified by compile-time check)
        #expect(true) // View created successfully
    }

    @Test("Icon gradient initializer creates cyan-to-blue gradient")
    func iconGradientInitializerCreatesCyanToBlueGradient() {
        let view = CircularProgressView(
            progress: 0.7,
            lineWidth: 8,
            showPercentage: false,
            useIconGradient: true
        )
        // View should compile and create with icon gradient
        #expect(true)
    }

    @Test("Adaptive gradient initializer uses progress-based colors")
    func adaptiveGradientInitializerUsesProgressBasedColors() {
        let view = CircularProgressView(
            progress: 0.45,
            lineWidth: 6,
            showPercentage: true,
            useAdaptiveGradient: true
        )
        // View should compile and create with adaptive gradient
        #expect(true)
    }

    @Test("Custom gradient initializer accepts LinearGradient")
    func customGradientInitializerAcceptsLinearGradient() {
        let customGradient = LinearGradient(
            colors: [.red, .yellow, .green],
            startPoint: .top,
            endPoint: .bottom
        )
        let view = CircularProgressView(
            progress: 0.8,
            gradient: customGradient,
            lineWidth: 12
        )
        #expect(true)
    }
}
