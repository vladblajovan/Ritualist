//
//  TestDataScenario.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on Test Data Scenarios Implementation
//

import Foundation

#if DEBUG

/// Predefined test data scenarios for debugging and testing
///
/// Each scenario represents a different user journey stage with specific data characteristics
/// that trigger different app behaviors and feature availability.
public enum TestDataScenario: String, CaseIterable, Identifiable, Sendable {
    // General scenarios
    case minimal = "Fresh Start"
    case moderate = "Building Momentum"
    case full = "Power User"

    // Big Five personality showcase scenarios
    case opennessProfile = "The Explorer"
    case conscientiousnessProfile = "The Achiever"
    case extraversionProfile = "The Connector"
    case agreeablenessProfile = "The Caregiver"
    case neuroticismProfile = "The Struggler"

    public var id: String { rawValue }

    /// User-friendly description of the scenario
    public var description: String {
        switch self {
        case .minimal:
            return "3 habits • 3 days • Insufficient for personality analysis"
        case .moderate:
            return "7 habits • 2 weeks • Health & Productivity focus"
        case .full:
            return "16 habits • 3 months • Balanced across all categories"
        case .opennessProfile:
            return "10 habits • Learning & Creativity • High Openness"
        case .conscientiousnessProfile:
            return "10 habits • Productivity & Health • 90% completion"
        case .extraversionProfile:
            return "10 habits • 100% Social category • High Extraversion"
        case .agreeablenessProfile:
            return "10 habits • Social + Wellness mix • High Agreeableness"
        case .neuroticismProfile:
            return "10 habits • 100% Health • 20% completion"
        }
    }

    /// Detailed explanation of what this scenario tests
    public var detailedDescription: String {
        switch self {
        case .minimal:
            return "Tests new user experience with minimal data. Personality analysis unavailable, basic metrics only."
        case .moderate:
            return "Tests minimum threshold state. Health and productivity habits with moderate completion."
        case .full:
            return "Tests power user with balanced personality. Equal habits across all 6 categories produce neutral scores."
        case .opennessProfile:
            return "Showcases Openness trait. 50% Learning + 50% Creativity habits produce highest openness scores."
        case .conscientiousnessProfile:
            return "Showcases Conscientiousness trait. 60% Productivity + 40% Health with 90%+ completion rate."
        case .extraversionProfile:
            return "Showcases Extraversion trait. 100% Social habits maximize the extraversion signal."
        case .agreeablenessProfile:
            return "Showcases Agreeableness trait. 40% Social + 60% Wellness dilutes extraversion, agreeableness wins."
        case .neuroticismProfile:
            return "Showcases Neuroticism trait. 100% Health habits with very low completion (20%) triggers instability."
        }
    }

    /// Icon representing the scenario
    public var icon: String {
        switch self {
        case .minimal: return "🌱"
        case .moderate: return "📈"
        case .full: return "🚀"
        case .opennessProfile: return "🔭"
        case .conscientiousnessProfile: return "🎯"
        case .extraversionProfile: return "🤝"
        case .agreeablenessProfile: return "💝"
        case .neuroticismProfile: return "😰"
        }
    }

    /// Color scheme for the scenario
    public var color: String {
        switch self {
        case .minimal: return "orange"
        case .moderate: return "blue"
        case .full: return "green"
        case .opennessProfile: return "purple"
        case .conscientiousnessProfile: return "blue"
        case .extraversionProfile: return "yellow"
        case .agreeablenessProfile: return "pink"
        case .neuroticismProfile: return "red"
        }
    }
}

/// Configuration parameters for test data generation based on scenario
public struct TestDataScenarioConfig {
    /// Number of suggested habits to create from predefined suggestions
    public let suggestedHabitCount: Int

    /// Number of custom categories to create
    public let customCategoryCount: Int

    /// Number of custom habits to create
    public let customHabitCount: Int

    /// Number of days of historical data to generate
    public let historyDays: Int

    /// Range of daily completion rates to use for historical data
    public let completionRateRange: ClosedRange<Double>

    /// Total habit count (suggested + custom)
    public var totalHabitCount: Int {
        suggestedHabitCount + customHabitCount
    }

    /// Get configuration for a specific scenario
    public static func config(for scenario: TestDataScenario) -> TestDataScenarioConfig {
        switch scenario {
        case .minimal:
            // Fresh Start: Insufficient data for personality analysis
            // - Below 5 habit minimum
            // - Below 7 day tracking minimum
            // - Realistic: user only picked suggestions, no custom habits yet
            return TestDataScenarioConfig(
                suggestedHabitCount: 3,       // 3 from suggestions (typical new user)
                customCategoryCount: 0,       // No custom categories yet
                customHabitCount: 0,          // No custom habits yet
                historyDays: 3,               // Below 7-day minimum
                completionRateRange: 0.3...0.5  // Modest completion
            )

        case .moderate:
            // Building Momentum: Minimum threshold met for personality analysis
            // - Meets 5 habit minimum
            // - Meets 7 day tracking minimum
            // - 90/10 ratio: mostly from suggestions
            return TestDataScenarioConfig(
                suggestedHabitCount: 6,       // 6 from suggestions (90%)
                customCategoryCount: 1,       // 1 custom category
                customHabitCount: 1,          // 1 custom habit (10%, total: 7 habits)
                historyDays: 14,              // 2 weeks - above 7-day minimum
                completionRateRange: 0.4...0.7  // Moderate completion
            )

        case .full:
            // Power User: Balanced personality profile
            // Distribution: Equal across all 6 categories (~2-3 habits each)
            // This produces a balanced personality with no single dominant trait
            // 3 months of historical data, strong engagement
            return TestDataScenarioConfig(
                suggestedHabitCount: 14,      // ~2-3 per category across all 6 categories
                customCategoryCount: 2,       // 2 custom categories
                customHabitCount: 2,          // 2 custom habits (total: 16 habits)
                historyDays: 90,              // 3 months of rich history
                completionRateRange: 0.5...0.85  // Strong engagement with variation
            )

        case .opennessProfile:
            // The Explorer: Maximizes Openness score
            // Distribution: 50% Learning (openness: 0.8) + 50% Creativity (openness: 0.9)
            // Good completion (65-75%) shows engagement without perfectionism
            return TestDataScenarioConfig(
                suggestedHabitCount: 9,       // Split: ~5 learning + ~4 creativity
                customCategoryCount: 2,       // Creative custom categories
                customHabitCount: 1,          // 1 custom habit (total: 10)
                historyDays: 60,              // 2 months for pattern recognition
                completionRateRange: 0.65...0.75  // Good but not perfectionist
            )

        case .conscientiousnessProfile:
            // The Achiever: Maximizes Conscientiousness score
            // Distribution: 60% Productivity (conscientiousness: 0.8) + 40% Health (conscientiousness: 0.6)
            // Very high completion (85-95%) demonstrates discipline
            return TestDataScenarioConfig(
                suggestedHabitCount: 9,       // Split: ~6 productivity + ~3 health
                customCategoryCount: 2,       // Goal-oriented custom categories
                customHabitCount: 1,          // 1 custom habit (total: 10)
                historyDays: 60,              // 2 months of consistency
                completionRateRange: 0.85...0.95  // Very high completion - KEY for conscientiousness
            )

        case .extraversionProfile:
            // The Connector: Maximizes Extraversion score
            // Distribution: 100% Social (extraversion: 0.7)
            // Using only social category ensures extraversion dominates
            return TestDataScenarioConfig(
                suggestedHabitCount: 9,       // All 9 from social category
                customCategoryCount: 2,       // Social custom categories
                customHabitCount: 1,          // 1 custom habit (total: 10)
                historyDays: 60,              // 2 months of social engagement
                completionRateRange: 0.70...0.85  // Strong social commitment
            )

        case .agreeablenessProfile:
            // The Caregiver: Maximizes Agreeableness score
            // Distribution: 40% Social + 60% Wellness
            // Social has extraversion: 0.7 + agreeableness: 0.6
            // Wellness has agreeableness: 0.2 (dilutes extraversion, accumulates agreeableness)
            // This ratio ensures agreeableness beats extraversion
            return TestDataScenarioConfig(
                suggestedHabitCount: 9,       // Split: ~4 social + ~5 wellness
                customCategoryCount: 2,       // Care-focused custom categories
                customHabitCount: 1,          // 1 custom habit (total: 10)
                historyDays: 60,              // 2 months of caring patterns
                completionRateRange: 0.75...0.90  // Very reliable caregiving
            )

        case .neuroticismProfile:
            // The Struggler: Maximizes Neuroticism score
            // Distribution: 100% Health (NO openness weight - unlike Wellness which has openness: 0.3)
            // Health has: conscientiousness: 0.6, neuroticism: -0.3, agreeableness: 0.2
            // KEY: Very low completion (15-25%) triggers algorithm's instability detection
            // The algorithm adds strong neuroticism when completion < 30%
            return TestDataScenarioConfig(
                suggestedHabitCount: 9,       // All 9 from health category
                customCategoryCount: 2,       // Stress-related custom categories
                customHabitCount: 1,          // 1 custom habit (total: 10)
                historyDays: 60,              // 2 months of struggle
                completionRateRange: 0.15...0.25  // Very low completion - KEY for neuroticism
            )
        }
    }
}

/// Expected feature availability for each scenario
/// Useful for documentation and testing validation
public struct ScenarioFeatureAvailability {
    public let personalityAnalysisAvailable: Bool
    public let personalityAnalysisConfidence: String
    public let dashboardMetricsLevel: String
    public let streaksAvailable: Bool
    public let historicalChartsDepth: String

    public static func availability(for scenario: TestDataScenario) -> ScenarioFeatureAvailability {
        switch scenario {
        case .minimal:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: false,
                personalityAnalysisConfidence: "N/A",
                dashboardMetricsLevel: "Basic only",
                streaksAvailable: true,
                historicalChartsDepth: "3 days"
            )

        case .moderate:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: true,
                personalityAnalysisConfidence: "Low-Medium",
                dashboardMetricsLevel: "Most metrics",
                streaksAvailable: true,
                historicalChartsDepth: "2 weeks"
            )

        case .full:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: true,
                personalityAnalysisConfidence: "High",
                dashboardMetricsLevel: "All metrics",
                streaksAvailable: true,
                historicalChartsDepth: "3 months"
            )

        case .opennessProfile:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: true,
                personalityAnalysisConfidence: "High - Openness",
                dashboardMetricsLevel: "All metrics",
                streaksAvailable: true,
                historicalChartsDepth: "2 months"
            )

        case .conscientiousnessProfile:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: true,
                personalityAnalysisConfidence: "High - Conscientiousness",
                dashboardMetricsLevel: "All metrics",
                streaksAvailable: true,
                historicalChartsDepth: "2 months"
            )

        case .extraversionProfile:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: true,
                personalityAnalysisConfidence: "High - Extraversion",
                dashboardMetricsLevel: "All metrics",
                streaksAvailable: true,
                historicalChartsDepth: "2 months"
            )

        case .agreeablenessProfile:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: true,
                personalityAnalysisConfidence: "High - Agreeableness",
                dashboardMetricsLevel: "All metrics",
                streaksAvailable: true,
                historicalChartsDepth: "2 months"
            )

        case .neuroticismProfile:
            return ScenarioFeatureAvailability(
                personalityAnalysisAvailable: true,
                personalityAnalysisConfidence: "High - Neuroticism",
                dashboardMetricsLevel: "All metrics",
                streaksAvailable: true,
                historicalChartsDepth: "2 months"
            )
        }
    }
}

#endif
