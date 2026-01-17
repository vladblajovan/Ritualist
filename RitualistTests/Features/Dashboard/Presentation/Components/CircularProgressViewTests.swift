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

    @Test("Very low completion (0-24%) uses muted red gradient")
    func veryLowCompletionUsesMutedRedGradient() {
        let colors0 = CircularProgressView.adaptiveProgressColors(for: 0.0)
        let colors10 = CircularProgressView.adaptiveProgressColors(for: 0.10)
        let colors24 = CircularProgressView.adaptiveProgressColors(for: 0.24)

        // First color should be ritualistIconBackground
        #expect(colors0[0] == Color.ritualistIconBackground)
        #expect(colors10[0] == Color.ritualistIconBackground)
        #expect(colors24[0] == Color.ritualistIconBackground)

        // Second color should be progressRed with opacity (muted)
        #expect(colors0[1] == CardDesign.progressRed.opacity(0.6))
        #expect(colors10[1] == CardDesign.progressRed.opacity(0.6))
        #expect(colors24[1] == CardDesign.progressRed.opacity(0.6))
    }

    @Test("Low completion (25-49%) uses coral gradient")
    func lowCompletionUsesCoralGradient() {
        let colors25 = CircularProgressView.adaptiveProgressColors(for: 0.25)
        let colors35 = CircularProgressView.adaptiveProgressColors(for: 0.35)
        let colors49 = CircularProgressView.adaptiveProgressColors(for: 0.49)

        // First color should be ritualistIconBackground
        #expect(colors25[0] == Color.ritualistIconBackground)
        #expect(colors35[0] == Color.ritualistIconBackground)
        #expect(colors49[0] == Color.ritualistIconBackground)

        // Second color should be progressCoral (getting started)
        #expect(colors25[1] == CardDesign.progressCoral)
        #expect(colors35[1] == CardDesign.progressCoral)
        #expect(colors49[1] == CardDesign.progressCoral)
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

    @Test("High completion (80-99%) uses light green gradient")
    func highCompletionUsesLightGreenGradient() {
        let colors80 = CircularProgressView.adaptiveProgressColors(for: 0.80)
        let colors90 = CircularProgressView.adaptiveProgressColors(for: 0.90)
        let colors99 = CircularProgressView.adaptiveProgressColors(for: 0.99)

        // 80-99% should include progressLightGreen as second color
        #expect(colors80[1] == CardDesign.progressLightGreen)
        #expect(colors90[1] == CardDesign.progressLightGreen)
        #expect(colors99[1] == CardDesign.progressLightGreen)
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
        #expect(colorsNegative[1] == CardDesign.progressRed.opacity(0.6)) // 0% = muted red

        // Progress > 1 should be treated as 1
        let colorsOver = CircularProgressView.adaptiveProgressColors(for: 1.5)
        #expect(colorsOver[1] == CardDesign.progressGreen) // 100% = green
    }

    @Test("Exact threshold values produce correct colors")
    func exactThresholdValuesProduceCorrectColors() {
        // Test exact threshold boundaries
        // 0.25 threshold: should be coral (>= 0.25)
        let colors25 = CircularProgressView.adaptiveProgressColors(for: 0.25)
        #expect(colors25[1] == CardDesign.progressCoral)

        // 0.5 threshold: should be orange (>= 0.5)
        let colors50 = CircularProgressView.adaptiveProgressColors(for: 0.5)
        #expect(colors50[1] == CardDesign.progressOrange)

        // 0.8 threshold: should be light green (80-99%)
        let colors80 = CircularProgressView.adaptiveProgressColors(for: 0.8)
        #expect(colors80[1] == CardDesign.progressLightGreen)

        // Just below thresholds
        let colors249 = CircularProgressView.adaptiveProgressColors(for: 0.249)
        #expect(colors249[1] == CardDesign.progressRed.opacity(0.6))

        let colors499 = CircularProgressView.adaptiveProgressColors(for: 0.499)
        #expect(colors499[1] == CardDesign.progressCoral)

        let colors799 = CircularProgressView.adaptiveProgressColors(for: 0.799)
        #expect(colors799[1] == CardDesign.progressOrange)
    }
}
