//
//  CircularProgressViewTests.swift
//  RitualistTests
//
//  Tests for CircularProgressView adaptive gradient logic
//

import Foundation
import Testing
import SwiftUI
@testable import RitualistCore
@testable import Ritualist

/// Tests for CircularProgressView adaptive gradient logic
@Suite("CircularProgressView - Adaptive Gradients")
@MainActor
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

        // First color should be ritualistIconBackground (adaptive brand color)
        #expect(colors0[0] == Color.ritualistIconBackground)
        #expect(colors25[0] == Color.ritualistIconBackground)
        #expect(colors49[0] == Color.ritualistIconBackground)

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

        #expect(colors100[0] == Color.ritualistIconBackground)
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
