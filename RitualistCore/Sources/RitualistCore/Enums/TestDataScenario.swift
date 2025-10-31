//
//  TestDataScenario.swift
//  RitualistCore
//
//  Created by Claude on Test Data Scenarios Implementation
//

import Foundation

#if DEBUG

/// Predefined test data scenarios for debugging and testing
///
/// Each scenario represents a different user journey stage with specific data characteristics
/// that trigger different app behaviors and feature availability.
public enum TestDataScenario: String, CaseIterable, Identifiable {
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
            return "6 habits • 2 weeks • Basic personality insights"
        case .full:
            return "15 habits • 3 months • Full analytics & rich insights"
        case .opennessProfile:
            return "10 diverse habits • Flexible schedules • High Openness"
        case .conscientiousnessProfile:
            return "12 structured habits • 90% completion • High Conscientiousness"
        case .extraversionProfile:
            return "10 social habits • Community focus • High Extraversion"
        case .agreeablenessProfile:
            return "10 caring habits • Relationship focus • High Agreeableness"
        case .neuroticismProfile:
            return "12 habits • 25% completion • High Neuroticism"
        }
    }

    /// Detailed explanation of what this scenario tests
    public var detailedDescription: String {
        switch self {
        case .minimal:
            return "Tests new user experience with minimal data. Personality analysis unavailable, basic metrics only."
        case .moderate:
            return "Tests minimum threshold state. Personality analysis available but with low confidence. Some metrics limited."
        case .full:
            return "Tests power user experience with rich historical data. Full personality analysis, all metrics, long streaks."
        case .opennessProfile:
            return "Showcases Openness personality trait. Diverse habit categories, flexible schedules, creative pursuits, learning focus."
        case .conscientiousnessProfile:
            return "Showcases Conscientiousness trait. Highly structured routines, excellent completion rates, goal-oriented behavior."
        case .extraversionProfile:
            return "Showcases Extraversion trait. Social habits, community engagement, team activities, relationship building."
        case .agreeablenessProfile:
            return "Showcases Agreeableness trait. Caring behaviors, helping others, family time, volunteer activities."
        case .neuroticismProfile:
            return "Showcases Neuroticism trait. Inconsistent patterns, low completion, emotional instability indicators."
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
            // - Below 3 custom category/habit minimums
            return TestDataScenarioConfig(
                suggestedHabitCount: 2,      // 2 from suggestions
                customCategoryCount: 1,       // Below minimum
                customHabitCount: 1,          // Below minimum
                historyDays: 3,               // Below 7-day minimum
                completionRateRange: 0.3...0.5  // Modest completion
            )

        case .moderate:
            // Building Momentum: Minimum threshold met for personality analysis
            // - Exactly meets 5 habit minimum
            // - Meets 7 day tracking minimum
            // - Meets 3 custom category/habit minimums
            return TestDataScenarioConfig(
                suggestedHabitCount: 3,       // 3 from suggestions
                customCategoryCount: 3,       // Meets minimum
                customHabitCount: 3,          // Meets minimum (total: 6 habits)
                historyDays: 14,              // 2 weeks - above 7-day minimum
                completionRateRange: 0.4...0.7  // Moderate completion
            )

        case .full:
            // Power User: Rich data for full personality analysis
            // - Well above all minimums
            // - 3 months of historical data
            // - Sophisticated completion patterns
            return TestDataScenarioConfig(
                suggestedHabitCount: 12,      // 12 from suggestions
                customCategoryCount: 3,       // Meets requirement
                customHabitCount: 3,          // Meets requirement (total: 15 habits)
                historyDays: 90,              // 3 months of rich history
                completionRateRange: 0.5...0.85  // Strong engagement with variation
            )

        case .opennessProfile:
            // The Explorer: Maximizes Openness score
            // - Diverse habits across many categories
            // - Flexible schedules (3x/week patterns)
            // - Creative/learning focus
            // - Moderate-high completion
            return TestDataScenarioConfig(
                suggestedHabitCount: 7,       // Diverse suggestions
                customCategoryCount: 3,       // Creative custom categories
                customHabitCount: 3,          // Unique custom habits (total: 10)
                historyDays: 60,              // 2 months for pattern recognition
                completionRateRange: 0.65...0.75  // Good but not perfectionist
            )

        case .conscientiousnessProfile:
            // The Achiever: Maximizes Conscientiousness score
            // - Highly structured daily routines
            // - Excellent completion rates
            // - Goal-oriented habits
            // - Consistent patterns
            return TestDataScenarioConfig(
                suggestedHabitCount: 9,       // Structured suggestions
                customCategoryCount: 3,       // Goal categories
                customHabitCount: 3,          // Achievement habits (total: 12)
                historyDays: 60,              // 2 months of consistency
                completionRateRange: 0.85...0.95  // Very high completion
            )

        case .extraversionProfile:
            // The Connector: Maximizes Extraversion score
            // - Social interaction habits
            // - Community/team activities
            // - Relationship building
            // - Good completion on social habits
            return TestDataScenarioConfig(
                suggestedHabitCount: 4,       // Some social suggestions
                customCategoryCount: 3,       // Social custom categories
                customHabitCount: 6,          // Many social custom habits (total: 10)
                historyDays: 60,              // 2 months of social engagement
                completionRateRange: 0.70...0.85  // Strong social commitment
            )

        case .agreeablenessProfile:
            // The Caregiver: Maximizes Agreeableness score
            // - Care/helping habits
            // - Family/relationship focus
            // - Volunteering activities
            // - High completion on care habits
            return TestDataScenarioConfig(
                suggestedHabitCount: 4,       // Some care suggestions
                customCategoryCount: 3,       // Care custom categories
                customHabitCount: 6,          // Many care custom habits (total: 10)
                historyDays: 60,              // 2 months of caring patterns
                completionRateRange: 0.75...0.90  // Very reliable caregiving
            )

        case .neuroticismProfile:
            // The Struggler: Maximizes Neuroticism score
            // - Inconsistent completion patterns
            // - Many started but not maintained
            // - Emotional instability indicators
            // - Low overall completion
            return TestDataScenarioConfig(
                suggestedHabitCount: 9,       // Many attempts
                customCategoryCount: 3,       // Standard categories
                customHabitCount: 3,          // Standard custom habits (total: 12)
                historyDays: 60,              // 2 months of struggle
                completionRateRange: 0.15...0.30  // Low, erratic completion
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
