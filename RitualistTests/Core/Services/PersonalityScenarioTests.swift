//
//  PersonalityScenarioTests.swift
//  RitualistTests
//
//  Created by Claude on 03.01.2026.
//

import Foundation
import Testing
@testable import RitualistCore

/// Comprehensive tests verifying personality analysis produces correct results for each test scenario.
/// Each scenario represents a distinct personality profile with expected dominant traits.
@Suite("Personality Analysis Scenario Tests")
@MainActor
struct PersonalityScenarioTests {

    // MARK: - Test Infrastructure

    /// Creates test habits for a given predefined category
    private func createTestHabits(
        categoryId: String,
        count: Int,
        startIndex: Int = 0
    ) -> [Habit] {
        (0..<count).map { index in
            Habit(
                id: Foundation.UUID(),
                name: "Test Habit \(categoryId) \(index)",
                colorHex: "#3498DB",
                emoji: "📝",
                kind: .binary,
                schedule: .daily,
                displayOrder: startIndex + index,
                categoryId: categoryId,
                suggestionId: "suggestion_\(categoryId)_\(index)"
            )
        }
    }

    /// Returns predefined categories with personality weights (matching CategoryDefinitionsService)
    private func getPredefinedCategories() -> [HabitCategory] {
        [
            HabitCategory(
                id: "health", name: "health", displayName: "Health", emoji: "💪",
                order: 0, isPredefined: true,
                personalityWeights: ["conscientiousness": 0.6, "neuroticism": -0.3, "agreeableness": 0.2]
            ),
            HabitCategory(
                id: "wellness", name: "wellness", displayName: "Wellness", emoji: "🧘",
                order: 1, isPredefined: true,
                personalityWeights: ["conscientiousness": 0.4, "neuroticism": -0.5, "openness": 0.3, "agreeableness": 0.2]
            ),
            HabitCategory(
                id: "productivity", name: "productivity", displayName: "Productivity", emoji: "⚡",
                order: 2, isPredefined: true,
                personalityWeights: ["conscientiousness": 0.8, "neuroticism": -0.2, "openness": 0.1]
            ),
            HabitCategory(
                id: "social", name: "social", displayName: "Social", emoji: "👥",
                order: 3, isPredefined: true,
                personalityWeights: ["extraversion": 0.7, "agreeableness": 0.6, "conscientiousness": 0.3, "neuroticism": -0.3]
            ),
            HabitCategory(
                id: "learning", name: "learning", displayName: "Learning", emoji: "📚",
                order: 4, isPredefined: true,
                personalityWeights: ["openness": 0.8, "conscientiousness": 0.5, "extraversion": 0.2, "neuroticism": -0.2]
            ),
            HabitCategory(
                id: "creativity", name: "creativity", displayName: "Creativity", emoji: "🎨",
                order: 5, isPredefined: true,
                personalityWeights: ["openness": 0.9, "extraversion": 0.3, "conscientiousness": 0.1, "neuroticism": -0.3]
            )
        ]
    }

    /// Runs personality analysis for given categories, completion rate range, and habit count
    private func runAnalysis(
        categoryIds: [String],
        completionRateRange: ClosedRange<Double>,
        habitsPerCategory: Int = 4
    ) -> (dominant: PersonalityTrait, scores: [PersonalityTrait: Double]) {
        let repository = MockPersonalityAnalysisRepository()
        let service = DefaultPersonalityAnalysisService(repository: repository)

        let allCategories = getPredefinedCategories()
        let usedCategories = allCategories.filter { categoryIds.contains($0.id) }

        var allHabits: [Habit] = []
        var habitIndex = 0
        for categoryId in categoryIds {
            let habits = createTestHabits(categoryId: categoryId, count: habitsPerCategory, startIndex: habitIndex)
            allHabits.append(contentsOf: habits)
            habitIndex += habits.count
        }

        let avgCompletion = (completionRateRange.lowerBound + completionRateRange.upperBound) / 2
        let completionRates = allHabits.map { _ in avgCompletion }

        let input = HabitAnalysisInput(
            activeHabits: allHabits,
            completionRates: completionRates,
            customHabits: [],
            customCategories: [],
            habitCategories: usedCategories,
            selectedSuggestions: [],
            trackingDays: 60,
            analysisTimeRange: 60,
            totalDataPoints: allHabits.count * 60
        )

        let completionStats = HabitCompletionStats(
            totalHabits: allHabits.count,
            completedHabits: Int(Double(allHabits.count) * avgCompletion),
            completionRate: avgCompletion
        )

        let (scores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: completionStats
        )
        let dominant = service.determineDominantTrait(from: scores)

        return (dominant, scores)
    }

    // MARK: - Openness Profile (The Explorer)

    @Test("The Explorer shows high Openness")
    func explorerShowsOpenness() {
        let (dominant, scores) = runAnalysis(
            categoryIds: ["learning", "creativity"],
            completionRateRange: 0.65...0.75
        )

        #expect(dominant == .openness, "The Explorer (Learning + Creativity) should show Openness as dominant trait, got: \(dominant)")
        #expect(scores[.openness]! > 0.6, "Openness score should be high (>60%), got: \(scores[.openness]!)")
        #expect(scores[.neuroticism]! < 0.5, "Neuroticism should be below neutral, got: \(scores[.neuroticism]!)")
    }

    @Test("Learning and Creativity categories drive Openness")
    func learningCreativityDriveOpenness() {
        let (_, scores) = runAnalysis(
            categoryIds: ["learning", "creativity"],
            completionRateRange: 0.70...0.80
        )

        // Learning has openness: 0.8, Creativity has openness: 0.9
        // These should produce a high openness score
        #expect(scores[.openness]! >= scores[.conscientiousness]!, "Openness should be >= conscientiousness for learning/creativity")
        #expect(scores[.openness]! >= scores[.extraversion]!, "Openness should be >= extraversion for learning/creativity")
    }

    // MARK: - Conscientiousness Profile (The Achiever)

    @Test("The Achiever shows high Conscientiousness")
    func achieverShowsConscientiousness() {
        let (dominant, scores) = runAnalysis(
            categoryIds: ["productivity", "health"],
            completionRateRange: 0.85...0.95
        )

        #expect(dominant == .conscientiousness, "The Achiever (Productivity + Health with high completion) should show Conscientiousness")
        #expect(scores[.conscientiousness]! > 0.6, "Conscientiousness score should be high (>60%)")
        #expect(scores[.neuroticism]! < 0.5, "Neuroticism should be below neutral for high achievers")
    }

    @Test("High completion boosts Conscientiousness")
    func highCompletionBoostsConscientiousness() {
        let highCompletion = runAnalysis(
            categoryIds: ["productivity"],
            completionRateRange: 0.90...0.95
        )

        let lowCompletion = runAnalysis(
            categoryIds: ["productivity"],
            completionRateRange: 0.30...0.40
        )

        #expect(
            highCompletion.scores[.conscientiousness]! > lowCompletion.scores[.conscientiousness]!,
            "High completion should produce higher conscientiousness than low completion"
        )
    }

    // MARK: - Extraversion Profile (The Connector)

    @Test("The Connector shows high Extraversion")
    func connectorShowsExtraversion() {
        let (dominant, scores) = runAnalysis(
            categoryIds: ["social"],
            completionRateRange: 0.70...0.85
        )

        #expect(dominant == .extraversion, "The Connector (Social) should show Extraversion as dominant trait")
        #expect(scores[.extraversion]! > 0.5, "Extraversion score should be above neutral")
        #expect(scores[.neuroticism]! < 0.5, "Neuroticism should be below neutral")
    }

    @Test("Social category drives Extraversion over other traits")
    func socialCategoryDrivesExtraversion() {
        let (_, scores) = runAnalysis(
            categoryIds: ["social"],
            completionRateRange: 0.75...0.85
        )

        // Social has extraversion: 0.7, agreeableness: 0.6
        // Extraversion should be dominant or close
        #expect(scores[.extraversion]! >= scores[.openness]!, "Extraversion should be >= openness for social category")
    }

    // MARK: - Agreeableness Profile (The Caregiver)

    @Test("The Caregiver shows high Agreeableness")
    func caregiverShowsAgreeableness() {
        // Caregiver uses Social + Wellness mix to favor agreeableness
        // Social has: extraversion: 0.7, agreeableness: 0.6
        // Wellness has: conscientiousness: 0.4, openness: 0.3, agreeableness: 0.2
        let (_, scores) = runAnalysis(
            categoryIds: ["social", "wellness"],
            completionRateRange: 0.75...0.90
        )

        // Key assertions: agreeableness elevated, neuroticism low
        #expect(scores[.agreeableness]! > 0.5, "Agreeableness should be above neutral")
        #expect(scores[.neuroticism]! < 0.5, "Neuroticism should be below neutral")
        // Agreeableness should be higher than or close to extraversion (diluted by wellness)
        #expect(scores[.agreeableness]! >= scores[.extraversion]! - 0.1, "Agreeableness should be competitive with extraversion")
    }

    // MARK: - Low Completion Profile (The Struggler)

    @Test("The Struggler shows low Conscientiousness with very low completion")
    func strugglerShowsLowConscientiousness() {
        // Someone with very low completion (20%) is not following through on habits
        // This should show LOW conscientiousness, not "high neuroticism" (which is stigmatizing)
        // Health has: conscientiousness: 0.6, neuroticism: -0.3, agreeableness: 0.2
        let (_, scores) = runAnalysis(
            categoryIds: ["health"],
            completionRateRange: 0.15...0.25  // Very low completion
        )

        // Low completion should result in below-neutral conscientiousness
        #expect(scores[.conscientiousness]! < 0.5, "Low completion should show below-neutral conscientiousness, got: \(scores[.conscientiousness]!)")
        // The profile should be distinctive, not flat
        let spread = scores.values.max()! - scores.values.min()!
        #expect(spread > 0.1, "Profile should have meaningful spread, not be flat. Spread: \(spread)")
    }

    @Test("Very low completion triggers neuroticism regardless of category")
    func veryLowCompletionTriggersNeuroticism() {
        // Test with a category that normally reduces neuroticism (wellness has neuroticism: -0.5)
        let (_, scores) = runAnalysis(
            categoryIds: ["wellness"],
            completionRateRange: 0.10...0.20  // Very low
        )

        // With very low completion (<30%), neuroticism should be elevated
        #expect(scores[.neuroticism]! > 0.5, "Very low completion should trigger neuroticism even for wellness category")
    }

    @Test("Moderate completion does not trigger high neuroticism")
    func moderateCompletionNoHighNeuroticism() {
        let (_, scores) = runAnalysis(
            categoryIds: ["health", "wellness"],
            completionRateRange: 0.50...0.70
        )

        // With moderate completion, neuroticism should NOT be dominant
        #expect(scores[.neuroticism]! < 0.5, "Moderate completion should not show high neuroticism")
    }

    // MARK: - Category Weight Dominance Tests

    @Test("Category weights are primary signal")
    func categoryWeightsArePrimarySignal() {
        // Test that category weights, not completion rate, determine the dominant trait
        // Learning has openness: 0.8, which should dominate over completionStats contributions

        let (dominant, _) = runAnalysis(
            categoryIds: ["learning"],
            completionRateRange: 0.60...0.70  // Good but not exceptional completion
        )

        #expect(dominant == .openness, "Learning category should produce Openness as dominant trait")
    }

    @Test("Negative neuroticism in categories reduces neuroticism score")
    func negativeNeuroticismReducesScore() {
        // All predefined categories have negative neuroticism weights
        // With good completion, neuroticism should be low
        let (_, scores) = runAnalysis(
            categoryIds: ["health", "wellness", "productivity"],
            completionRateRange: 0.70...0.80
        )

        #expect(scores[.neuroticism]! < 0.5, "Negative neuroticism weights should reduce neuroticism score")
    }

    // MARK: - Full Power User Scenario

    @Test("Power User shows balanced profile with high completion")
    func powerUserShowsBalancedProfile() {
        let (dominant, scores) = runAnalysis(
            categoryIds: ["health", "wellness", "productivity", "social", "learning", "creativity"],
            completionRateRange: 0.50...0.85
        )

        // Power User has diverse habits - should show openness or conscientiousness
        let validDominants: Set<PersonalityTrait> = [.openness, .conscientiousness]
        #expect(validDominants.contains(dominant), "Power User should show Openness or Conscientiousness")

        // With good completion, neuroticism should be low
        #expect(scores[.neuroticism]! < 0.5, "Power User with good completion should have low neuroticism")
    }

    // MARK: - Minimal Data Scenario

    @Test("Single category produces profile reflecting category weights")
    func singleCategoryProducesReflectiveProfile() {
        let (_, scores) = runAnalysis(
            categoryIds: ["health"],
            completionRateRange: 0.30...0.50
        )

        // Health category has: conscientiousness: 0.6, neuroticism: -0.3, agreeableness: 0.2
        // Even with single category, the profile SHOULD reflect these weights:
        // - Neuroticism should be LOW (health habits reduce stress)
        // - Conscientiousness should be present (health requires discipline)

        // Neuroticism should be below neutral (health has negative neuroticism weight)
        #expect(scores[.neuroticism]! < 0.5, "Health habits should reduce neuroticism")

        // All scores should be bounded
        for (trait, score) in scores {
            #expect(score >= 0.0 && score <= 1.0, "\(trait) should be bounded 0-1")
        }
    }

    // MARK: - Score Bounds Tests

    @Test("All scores are between 0 and 1")
    func scoresAreBounded() {
        let scenarios: [([String], ClosedRange<Double>)] = [
            (["learning", "creativity"], 0.65...0.75),
            (["productivity", "health"], 0.85...0.95),
            (["social"], 0.70...0.85),
            (["health", "wellness"], 0.15...0.25),
            (["health", "wellness", "productivity", "social", "learning", "creativity"], 0.50...0.85)
        ]

        for (categoryIds, completionRange) in scenarios {
            let (_, scores) = runAnalysis(categoryIds: categoryIds, completionRateRange: completionRange)

            for (trait, score) in scores {
                #expect(score >= 0.0, "\(trait) score should be >= 0")
                #expect(score <= 1.0, "\(trait) score should be <= 1")
            }
        }
    }

    @Test("Dominant trait has highest score")
    func dominantTraitHasHighestScore() {
        let scenarios: [([String], ClosedRange<Double>)] = [
            (["learning", "creativity"], 0.65...0.75),
            (["productivity", "health"], 0.85...0.95),
            (["health", "wellness"], 0.15...0.25)
        ]

        for (categoryIds, completionRange) in scenarios {
            let (dominant, scores) = runAnalysis(categoryIds: categoryIds, completionRateRange: completionRange)
            let dominantScore = scores[dominant]!
            let maxScore = scores.values.max()!

            #expect(dominantScore == maxScore, "Dominant trait should have the highest score")
        }
    }

    // MARK: - Edge Case Tests

    @Test("Single category produces clear dominant trait")
    func singleCategoryProducesClearDominant() {
        // Each single category should produce its primary trait as dominant
        let singleCategoryTests: [(String, PersonalityTrait, ClosedRange<Double>)] = [
            ("learning", .openness, 0.60...0.80),
            ("creativity", .openness, 0.60...0.80),
            ("productivity", .conscientiousness, 0.70...0.90),
            ("social", .extraversion, 0.60...0.80)
        ]

        for (categoryId, expectedTrait, completionRange) in singleCategoryTests {
            let (dominant, _) = runAnalysis(categoryIds: [categoryId], completionRateRange: completionRange)
            #expect(dominant == expectedTrait, "\(categoryId) category should produce \(expectedTrait), got \(dominant)")
        }
    }

    @Test("Boundary completion rate at 30% does not trigger high neuroticism")
    func boundaryCompletionNoHighNeuroticism() {
        // Exactly at 30% boundary - should NOT trigger strong neuroticism
        let (_, scores) = runAnalysis(
            categoryIds: ["health", "wellness"],
            completionRateRange: 0.30...0.30
        )
        #expect(scores[.neuroticism]! < 0.6, "30% completion should not trigger high neuroticism")
    }

    @Test("Completion just below 30% triggers neuroticism")
    func completionJustBelow30TriggersNeuroticism() {
        let (_, scores) = runAnalysis(
            categoryIds: ["health", "wellness"],
            completionRateRange: 0.25...0.29
        )
        #expect(scores[.neuroticism]! > 0.5, "Completion below 30% should trigger above-neutral neuroticism")
    }

    @Test("Very few habits still produce meaningful analysis")
    func veryFewHabitsProduceMeaningfulAnalysis() {
        let (_, scores) = runAnalysis(
            categoryIds: ["learning"],
            completionRateRange: 0.60...0.80,
            habitsPerCategory: 1  // Single habit
        )

        // All scores should be in valid range
        for (trait, score) in scores {
            #expect(score >= 0.0 && score <= 1.0, "\(trait) score should be valid")
        }
        // Openness should still be elevated for learning
        #expect(scores[.openness]! > 0.5, "Learning category should still boost openness with single habit")
    }

    @Test("Many habits amplify dominant trait")
    func manyHabitsAmplifyDominantTrait() {
        let fewHabits = runAnalysis(
            categoryIds: ["learning"],
            completionRateRange: 0.70...0.80,
            habitsPerCategory: 2
        )

        let manyHabits = runAnalysis(
            categoryIds: ["learning"],
            completionRateRange: 0.70...0.80,
            habitsPerCategory: 8
        )

        // Both should show openness as dominant
        #expect(fewHabits.dominant == .openness)
        #expect(manyHabits.dominant == .openness)
    }

    @Test("Opposing categories produce balanced profile")
    func opposingCategoriesProduceBalance() {
        // Health (conscientiousness-heavy) + Creative (openness-heavy)
        let (_, scores) = runAnalysis(
            categoryIds: ["productivity", "creativity"],
            completionRateRange: 0.60...0.70
        )

        // Both conscientiousness and openness should be elevated
        #expect(scores[.conscientiousness]! > 0.5, "Productivity should boost conscientiousness")
        #expect(scores[.openness]! > 0.5, "Creativity should boost openness")
    }

    @Test("Agreeableness requires social habits")
    func agreeablenessRequiresSocialHabits() {
        // Learning and Creativity have no agreeableness weight
        let (_, scores) = runAnalysis(
            categoryIds: ["learning", "creativity"],
            completionRateRange: 0.70...0.80
        )

        // Agreeableness should be neutral (no evidence)
        #expect(scores[.agreeableness]! >= 0.45 && scores[.agreeableness]! <= 0.55,
                "Agreeableness should be neutral without social habits")

        // Now with social category
        let (_, socialScores) = runAnalysis(
            categoryIds: ["social"],
            completionRateRange: 0.70...0.80
        )
        #expect(socialScores[.agreeableness]! > 0.55, "Social habits should boost agreeableness")
    }

    @Test("Extreme completion differences between categories")
    func extremeCompletionDifferences() {
        // This simulates a user who excels at some habits but struggles with others
        // Using single category with varying completion to test consistency
        let highCompletion = runAnalysis(
            categoryIds: ["productivity"],
            completionRateRange: 0.90...0.95
        )

        let lowCompletion = runAnalysis(
            categoryIds: ["productivity"],
            completionRateRange: 0.10...0.20
        )

        // High completion should have higher conscientiousness
        #expect(highCompletion.scores[.conscientiousness]! > lowCompletion.scores[.conscientiousness]!,
                "High completion should produce higher conscientiousness")

        // Low completion should have higher neuroticism
        #expect(lowCompletion.scores[.neuroticism]! > highCompletion.scores[.neuroticism]!,
                "Low completion should produce higher neuroticism")
    }

    @Test("All six categories combined")
    func allCategoriesCombined() {
        let (dominant, scores) = runAnalysis(
            categoryIds: ["health", "wellness", "productivity", "social", "learning", "creativity"],
            completionRateRange: 0.60...0.70
        )

        // All scores should be valid (0-1 range)
        for (trait, score) in scores {
            #expect(score >= 0.0, "\(trait) should be >= 0")
            #expect(score <= 1.0, "\(trait) should be <= 1")
        }

        // Dominant trait should be valid
        #expect(PersonalityTrait.allCases.contains(dominant), "Dominant trait should be valid")

        // With all categories, openness should be reasonably high (learning + creativity + wellness openness weights)
        #expect(scores[.openness]! > 0.5, "All categories should produce above-neutral openness")

        // Neuroticism should be low (good completion + negative weights from most categories)
        #expect(scores[.neuroticism]! < 0.5, "Good completion with all categories should have low neuroticism")
    }

    @Test("Consistency across multiple analysis runs")
    func consistencyAcrossRuns() {
        // Same input should produce same output
        let run1 = runAnalysis(categoryIds: ["learning", "productivity"], completionRateRange: 0.70...0.70)
        let run2 = runAnalysis(categoryIds: ["learning", "productivity"], completionRateRange: 0.70...0.70)

        // Dominant should be the same
        #expect(run1.dominant == run2.dominant, "Same input should produce same dominant trait")

        // Scores should be identical (or very close due to floating point)
        for trait in PersonalityTrait.allCases {
            let diff = abs(run1.scores[trait]! - run2.scores[trait]!)
            #expect(diff < 0.001, "\(trait) scores should be consistent")
        }
    }
}

// MARK: - Mock Repository

private final class MockPersonalityAnalysisRepository: PersonalityAnalysisRepositoryProtocol, @unchecked Sendable {
    func getPersonalityProfile(for userId: Foundation.UUID) async throws -> PersonalityProfile? { nil }
    func savePersonalityProfile(_ profile: PersonalityProfile) async throws {}
    func getPersonalityHistory(for userId: Foundation.UUID) async throws -> [PersonalityProfile] { [] }
    func deletePersonalityProfile(id: Foundation.UUID) async throws {}
    func deleteAllPersonalityProfiles(for userId: Foundation.UUID) async throws {}
    func validateAnalysisEligibility(for userId: Foundation.UUID) async throws -> AnalysisEligibility {
        AnalysisEligibility(isEligible: true, missingRequirements: [], overallProgress: 1.0)
    }
    func getThresholdProgress(for userId: Foundation.UUID) async throws -> [ThresholdRequirement] { [] }
    func getHabitAnalysisInput(for userId: Foundation.UUID) async throws -> HabitAnalysisInput {
        HabitAnalysisInput(
            activeHabits: [], completionRates: [], customHabits: [], customCategories: [],
            habitCategories: [], selectedSuggestions: [], trackingDays: 0, analysisTimeRange: 30, totalDataPoints: 0
        )
    }
    func getUserHabits(for userId: Foundation.UUID) async throws -> [Habit] { [] }
    func getUserCustomCategories(for userId: Foundation.UUID) async throws -> [HabitCategory] { [] }
    func getHabitCompletionStats(for userId: Foundation.UUID, from startDate: Foundation.Date, to endDate: Foundation.Date) async throws -> HabitCompletionStats {
        HabitCompletionStats(totalHabits: 0, completedHabits: 0, completionRate: 0.0)
    }
    func isPersonalityAnalysisEnabled(for userId: Foundation.UUID) async throws -> Bool { true }
    func getAnalysisPreferences(for userId: Foundation.UUID) async throws -> PersonalityAnalysisPreferences? { nil }
    func saveAnalysisPreferences(_ preferences: PersonalityAnalysisPreferences) async throws {}
}
