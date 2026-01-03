//
//  TestDataScenarioDistributionTests.swift
//  RitualistTests
//
//  Created by Vlad Blajovan on 03.01.2026.
//

import Foundation
import Testing
@testable import RitualistCore

#if DEBUG

/// Tests verifying that test data scenarios produce the correct category distributions
/// to achieve the expected personality profile outcomes.
@Suite("Test Data Scenario Distribution Tests")
@MainActor
struct TestDataScenarioDistributionTests {

    // MARK: - Test Infrastructure

    /// Simulates the category distribution logic from PopulateTestData
    /// This mirrors getCategoryDistribution() to test distribution correctness
    private func getCategoryDistribution(for scenario: TestDataScenario, totalCount: Int) -> [String: Int] {
        switch scenario {
        case .opennessProfile:
            let half = totalCount / 2
            return ["learning": half, "creativity": totalCount - half]

        case .conscientiousnessProfile:
            let productivity = Int(Double(totalCount) * 0.6)
            return ["productivity": productivity, "health": totalCount - productivity]

        case .extraversionProfile:
            return ["social": totalCount]

        case .agreeablenessProfile:
            let social = Int(Double(totalCount) * 0.4)
            return ["social": social, "wellness": totalCount - social]

        case .neuroticismProfile:
            // 100% Health - wellness has openness: 0.3 which competes with neuroticism
            return ["health": totalCount]

        case .full:
            let perCategory = totalCount / 6
            let remainder = totalCount % 6
            return [
                "health": perCategory + (remainder > 0 ? 1 : 0),
                "wellness": perCategory + (remainder > 1 ? 1 : 0),
                "productivity": perCategory + (remainder > 2 ? 1 : 0),
                "learning": perCategory + (remainder > 3 ? 1 : 0),
                "social": perCategory + (remainder > 4 ? 1 : 0),
                "creativity": perCategory
            ]

        case .moderate:
            return ["health": 2, "wellness": 1, "productivity": 2, "learning": 1, "social": 0, "creativity": 0]

        case .minimal:
            return ["health": 2, "productivity": 1]
        }
    }

    // MARK: - The Explorer (Openness) Tests

    @Test("Explorer uses only Learning and Creativity categories")
    func explorerUsesCorrectCategories() {
        let config = TestDataScenarioConfig.config(for: .opennessProfile)
        let distribution = getCategoryDistribution(for: .opennessProfile, totalCount: config.suggestedHabitCount)

        // Should only have learning and creativity
        let categories = Set(distribution.keys)
        #expect(categories == Set(["learning", "creativity"]))
    }

    @Test("Explorer has 50/50 split between Learning and Creativity")
    func explorerHasBalancedSplit() {
        let distribution = getCategoryDistribution(for: .opennessProfile, totalCount: 10)

        #expect(distribution["learning"] == 5)
        #expect(distribution["creativity"] == 5)
    }

    @Test("Explorer completion rate is moderate (65-75%)")
    func explorerHasModerateCompletion() {
        let config = TestDataScenarioConfig.config(for: .opennessProfile)

        #expect(config.completionRateRange.lowerBound >= 0.6)
        #expect(config.completionRateRange.upperBound <= 0.8)
    }

    // MARK: - The Achiever (Conscientiousness) Tests

    @Test("Achiever uses only Productivity and Health categories")
    func achieverUsesCorrectCategories() {
        let config = TestDataScenarioConfig.config(for: .conscientiousnessProfile)
        let distribution = getCategoryDistribution(for: .conscientiousnessProfile, totalCount: config.suggestedHabitCount)

        let categories = Set(distribution.keys)
        #expect(categories == Set(["productivity", "health"]))
    }

    @Test("Achiever favors Productivity over Health (60/40)")
    func achieverFavorsProductivity() {
        let distribution = getCategoryDistribution(for: .conscientiousnessProfile, totalCount: 10)

        #expect(distribution["productivity"] == 6)
        #expect(distribution["health"] == 4)
    }

    @Test("Achiever has very high completion rate (85-95%)")
    func achieverHasHighCompletion() {
        let config = TestDataScenarioConfig.config(for: .conscientiousnessProfile)

        #expect(config.completionRateRange.lowerBound >= 0.85)
        #expect(config.completionRateRange.upperBound <= 1.0)
    }

    // MARK: - The Connector (Extraversion) Tests

    @Test("Connector uses only Social category")
    func connectorUsesOnlySocial() {
        let config = TestDataScenarioConfig.config(for: .extraversionProfile)
        let distribution = getCategoryDistribution(for: .extraversionProfile, totalCount: config.suggestedHabitCount)

        let categories = Set(distribution.keys)
        #expect(categories == Set(["social"]))
    }

    @Test("Connector has 100% Social habits")
    func connectorIsAllSocial() {
        let distribution = getCategoryDistribution(for: .extraversionProfile, totalCount: 9)

        #expect(distribution["social"] == 9)
        #expect(distribution.count == 1)
    }

    // MARK: - The Caregiver (Agreeableness) Tests

    @Test("Caregiver uses Social and Wellness categories")
    func caregiverUsesCorrectCategories() {
        let config = TestDataScenarioConfig.config(for: .agreeablenessProfile)
        let distribution = getCategoryDistribution(for: .agreeablenessProfile, totalCount: config.suggestedHabitCount)

        let categories = Set(distribution.keys)
        #expect(categories == Set(["social", "wellness"]))
    }

    @Test("Caregiver favors Wellness over Social (60/40) to beat Extraversion")
    func caregiverFavorsWellness() {
        let distribution = getCategoryDistribution(for: .agreeablenessProfile, totalCount: 10)

        // 40% social, 60% wellness
        #expect(distribution["social"] == 4)
        #expect(distribution["wellness"] == 6)
    }

    @Test("Caregiver has high completion rate (75-90%)")
    func caregiverHasHighCompletion() {
        let config = TestDataScenarioConfig.config(for: .agreeablenessProfile)

        #expect(config.completionRateRange.lowerBound >= 0.7)
        #expect(config.completionRateRange.upperBound <= 0.95)
    }

    // MARK: - The Struggler (Neuroticism) Tests

    @Test("Struggler uses only Health category (no Wellness - it has openness)")
    func strugglerUsesCorrectCategories() {
        let config = TestDataScenarioConfig.config(for: .neuroticismProfile)
        let distribution = getCategoryDistribution(for: .neuroticismProfile, totalCount: config.suggestedHabitCount)

        let categories = Set(distribution.keys)
        #expect(categories == Set(["health"]))
    }

    @Test("Struggler has 100% Health habits")
    func strugglerIsAllHealth() {
        let distribution = getCategoryDistribution(for: .neuroticismProfile, totalCount: 10)

        #expect(distribution["health"] == 10)
        #expect(distribution.count == 1)
    }

    @Test("Struggler has very low completion rate (<30%) to trigger neuroticism")
    func strugglerHasVeryLowCompletion() {
        let config = TestDataScenarioConfig.config(for: .neuroticismProfile)

        // Must be below 30% to trigger neuroticism instability in algorithm
        #expect(config.completionRateRange.lowerBound < 0.3)
        #expect(config.completionRateRange.upperBound < 0.3)
    }

    // MARK: - Power User (Balanced) Tests

    @Test("Power User uses all 6 categories")
    func powerUserUsesAllCategories() {
        let config = TestDataScenarioConfig.config(for: .full)
        let distribution = getCategoryDistribution(for: .full, totalCount: config.suggestedHabitCount)

        let categories = Set(distribution.keys)
        let expectedCategories = Set(["health", "wellness", "productivity", "learning", "social", "creativity"])
        #expect(categories == expectedCategories)
    }

    @Test("Power User has roughly equal distribution across categories")
    func powerUserHasBalancedDistribution() {
        let distribution = getCategoryDistribution(for: .full, totalCount: 12)

        // With 12 habits across 6 categories, should be 2 each
        for (_, count) in distribution {
            #expect(count == 2)
        }
    }

    @Test("Power User handles uneven division correctly")
    func powerUserHandlesUnevenDivision() {
        let distribution = getCategoryDistribution(for: .full, totalCount: 14)

        // 14 / 6 = 2 with remainder 2
        // First 2 categories get 3, rest get 2
        let total = distribution.values.reduce(0, +)
        #expect(total == 14)

        // Check each category has 2 or 3
        for (_, count) in distribution {
            #expect(count >= 2 && count <= 3)
        }
    }

    // MARK: - Moderate Scenario Tests

    @Test("Moderate uses Health, Wellness, Productivity, Learning categories")
    func moderateUsesCorrectCategories() {
        let distribution = getCategoryDistribution(for: .moderate, totalCount: 6)

        #expect(distribution["health"] == 2)
        #expect(distribution["wellness"] == 1)
        #expect(distribution["productivity"] == 2)
        #expect(distribution["learning"] == 1)
        #expect(distribution["social"] == 0)
        #expect(distribution["creativity"] == 0)
    }

    // MARK: - Minimal Scenario Tests

    @Test("Minimal uses only Health and Productivity")
    func minimalUsesCorrectCategories() {
        let distribution = getCategoryDistribution(for: .minimal, totalCount: 3)

        #expect(distribution["health"] == 2)
        #expect(distribution["productivity"] == 1)
    }

    @Test("Minimal has insufficient data for personality analysis")
    func minimalHasInsufficientData() {
        let config = TestDataScenarioConfig.config(for: .minimal)

        // Below 5 habit minimum
        #expect(config.totalHabitCount < 5)
        // Below 7 day minimum
        #expect(config.historyDays < 7)
    }

    // MARK: - Cross-Scenario Validation

    @Test("All personality scenarios have at least 60 history days")
    func personalityScenariosHaveSufficientHistory() {
        let personalityScenarios: [TestDataScenario] = [
            .opennessProfile,
            .conscientiousnessProfile,
            .extraversionProfile,
            .agreeablenessProfile,
            .neuroticismProfile
        ]

        for scenario in personalityScenarios {
            let config = TestDataScenarioConfig.config(for: scenario)
            #expect(config.historyDays >= 60, "Scenario \(scenario.rawValue) should have at least 60 days history")
        }
    }

    @Test("All personality scenarios produce at least 10 total habits")
    func personalityScenariosHaveSufficientHabits() {
        let personalityScenarios: [TestDataScenario] = [
            .opennessProfile,
            .conscientiousnessProfile,
            .extraversionProfile,
            .agreeablenessProfile,
            .neuroticismProfile
        ]

        for scenario in personalityScenarios {
            let config = TestDataScenarioConfig.config(for: scenario)
            #expect(config.totalHabitCount >= 10, "Scenario \(scenario.rawValue) should have at least 10 habits")
        }
    }

    @Test("Distribution totals match suggested habit counts")
    func distributionTotalsMatchConfig() {
        let scenarios: [TestDataScenario] = TestDataScenario.allCases

        for scenario in scenarios {
            let config = TestDataScenarioConfig.config(for: scenario)
            let distribution = getCategoryDistribution(for: scenario, totalCount: config.suggestedHabitCount)
            let total = distribution.values.reduce(0, +)

            // For minimal and moderate, distribution may be fixed and not match suggestedHabitCount exactly
            // For personality and full scenarios, should match
            if scenario == .minimal || scenario == .moderate {
                #expect(total <= config.suggestedHabitCount, "Scenario \(scenario.rawValue) distribution should not exceed suggested count")
            } else {
                #expect(total == config.suggestedHabitCount, "Scenario \(scenario.rawValue) distribution total should match suggested count")
            }
        }
    }
}

#endif
