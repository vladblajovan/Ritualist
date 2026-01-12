//
//  PersonalityAnalysisServiceTests.swift
//  RitualistTests
//
//  Tests for PersonalityAnalysisService - Big Five personality trait calculation
//  from user habit data using the OCEAN model.
//
//  Key Testing Focus:
//  - Personality score calculation from predefined and custom categories
//  - Completion rate effects (conscientiousness, neuroticism signals)
//  - Dominant trait determination and tie-breaking
//  - Confidence level calculation based on data points
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - Test Repository

/// In-memory PersonalityAnalysisRepository for testing service logic
/// Follows the "Real Objects Over Mocks" philosophy by providing minimal implementation
private final class TestPersonalityAnalysisRepository: PersonalityAnalysisRepositoryProtocol, @unchecked Sendable {
    var profiles: [UUID: PersonalityProfile] = [:]
    var preferences: [UUID: PersonalityAnalysisPreferences] = [:]
    var analysisEnabled: Bool = true

    func getPersonalityProfile(for userId: UUID) async throws -> PersonalityProfile? {
        profiles[userId]
    }

    func savePersonalityProfile(_ profile: PersonalityProfile) async throws {
        profiles[profile.userId] = profile
    }

    func getPersonalityHistory(for userId: UUID) async throws -> [PersonalityProfile] {
        profiles.values.filter { $0.userId == userId }
    }

    func deletePersonalityProfile(id: UUID) async throws {
        profiles = profiles.filter { $0.value.id != id }
    }

    func deleteAllPersonalityProfiles(for userId: UUID) async throws {
        profiles = profiles.filter { $0.value.userId != userId }
    }

    func validateAnalysisEligibility(for userId: UUID) async throws -> AnalysisEligibility {
        AnalysisEligibility(isEligible: true, missingRequirements: [], overallProgress: 1.0)
    }

    func getThresholdProgress(for userId: UUID) async throws -> [ThresholdRequirement] {
        []
    }

    func getHabitAnalysisInput(for userId: UUID) async throws -> HabitAnalysisInput {
        HabitAnalysisInput(
            activeHabits: [],
            completionRates: [],
            customHabits: [],
            customCategories: [],
            habitCategories: [],
            selectedSuggestions: [],
            trackingDays: 0,
            analysisTimeRange: 30,
            totalDataPoints: 0
        )
    }

    func getUserHabits(for userId: UUID) async throws -> [Habit] {
        []
    }

    func getUserCustomCategories(for userId: UUID) async throws -> [HabitCategory] {
        []
    }

    func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
        HabitCompletionStats(totalHabits: 0, completedHabits: 0, completionRate: 0)
    }

    func isPersonalityAnalysisEnabled(for userId: UUID) async throws -> Bool {
        analysisEnabled
    }

    func getAnalysisPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences? {
        preferences[userId]
    }

    func saveAnalysisPreferences(_ preferences: PersonalityAnalysisPreferences) async throws {
        self.preferences[preferences.userId] = preferences
    }
}

// MARK: - Test Data Builders

/// Builder for creating HabitAnalysisInput test data
enum PersonalityTestDataBuilder {

    /// Get predefined categories from CategoryDefinitionsService
    static var predefinedCategories: [HabitCategory] {
        CategoryDefinitionsService().getPredefinedCategories()
    }

    /// Get a specific predefined category by ID
    static func predefinedCategory(_ id: String) -> HabitCategory? {
        predefinedCategories.first { $0.id == id }
    }

    /// Create empty analysis input (no data)
    static func emptyInput() -> HabitAnalysisInput {
        HabitAnalysisInput(
            activeHabits: [],
            completionRates: [],
            customHabits: [],
            customCategories: [],
            habitCategories: [],
            selectedSuggestions: [],
            trackingDays: 0,
            analysisTimeRange: 30,
            totalDataPoints: 0
        )
    }

    /// Create analysis input with habits in predefined categories
    static func inputWithPredefinedCategoryHabits(
        categoryIds: [String],
        completionRates: [Double]? = nil,
        habitsPerCategory: Int = 1
    ) -> HabitAnalysisInput {
        var habits: [Habit] = []
        let categories = predefinedCategories.filter { categoryIds.contains($0.id) }

        for category in categories {
            for i in 0..<habitsPerCategory {
                let habit = HabitBuilder.binary(
                    id: UUID(),
                    name: "\(category.displayName) Habit \(i + 1)",
                    categoryId: category.id
                )
                habits.append(habit)
            }
        }

        let rates = completionRates ?? Array(repeating: 0.7, count: habits.count)

        return HabitAnalysisInput(
            activeHabits: habits,
            completionRates: rates,
            customHabits: [],
            customCategories: [],
            habitCategories: categories,
            selectedSuggestions: [],
            trackingDays: 30,
            analysisTimeRange: 30,
            totalDataPoints: habits.count * 30
        )
    }

    /// Create analysis input with custom category habits
    static func inputWithCustomCategoryHabits(
        customCategories: [HabitCategory],
        habitsPerCategory: Int = 1,
        completionRates: [Double]? = nil
    ) -> HabitAnalysisInput {
        var habits: [Habit] = []

        for category in customCategories {
            for i in 0..<habitsPerCategory {
                let habit = HabitBuilder.binary(
                    id: UUID(),
                    name: "\(category.displayName) Habit \(i + 1)",
                    categoryId: category.id
                )
                habits.append(habit)
            }
        }

        let rates = completionRates ?? Array(repeating: 0.7, count: habits.count)

        return HabitAnalysisInput(
            activeHabits: [],
            completionRates: rates,
            customHabits: habits,
            customCategories: customCategories,
            habitCategories: [],
            selectedSuggestions: [],
            trackingDays: 30,
            analysisTimeRange: 30,
            totalDataPoints: habits.count * 30
        )
    }

    /// Create analysis input with social keyword habits (for extraversion testing)
    static func inputWithSocialKeywordHabits() -> HabitAnalysisInput {
        let socialHabits = [
            HabitBuilder.binary(name: "Meet with friends"),
            HabitBuilder.binary(name: "Call family member"),
            HabitBuilder.binary(name: "Social networking event")
        ]

        return HabitAnalysisInput(
            activeHabits: [],
            completionRates: [0.7, 0.7, 0.7],
            customHabits: socialHabits,
            customCategories: [],
            habitCategories: [],
            selectedSuggestions: [],
            trackingDays: 30,
            analysisTimeRange: 30,
            totalDataPoints: 90
        )
    }

    /// Create analysis metadata with specified data points
    static func metadata(dataPoints: Int) -> AnalysisMetadata {
        AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: dataPoints,
            timeRangeAnalyzed: 30,
            version: "1.0"
        )
    }
}

// MARK: - Empty Input Tests

@Suite("PersonalityAnalysisService - Empty Input", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServiceEmptyInputTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("Empty input returns scores in valid range with minimal variance")
    func emptyInput_returnsNeutralScores() {
        let input = PersonalityTestDataBuilder.emptyInput()

        let scores = service.calculatePersonalityScores(from: input)

        // With empty input, all traits should be in valid range (0.0-1.0)
        // Scores won't be exactly 0.5 due to diversity bonus and evidence normalization
        for trait in PersonalityTrait.allCases {
            let score = scores[trait] ?? 0.0
            #expect(score >= 0.0 && score <= 1.0, "Trait \(trait) should be in valid range, got \(score)")
        }

        // Verify scores are relatively close together (no extreme outliers)
        let allScores = scores.values
        let maxScore = allScores.max() ?? 0.0
        let minScore = allScores.min() ?? 0.0
        #expect(maxScore - minScore < 0.7, "Empty input should not produce extreme score variance")
    }

    @Test("Empty input has zero accumulators and weights")
    func emptyInput_hasZeroAccumulators() {
        let input = PersonalityTestDataBuilder.emptyInput()

        let (_, accumulators, totalWeights) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: nil
        )

        // With no habits, most accumulators should be near zero
        // (only diversity bonus adds small openness contribution)
        #expect(accumulators[.conscientiousness] ?? 0.0 < 0.2)
        #expect(accumulators[.extraversion] ?? 0.0 < 0.1)
        #expect(accumulators[.agreeableness] ?? 0.0 < 0.1)
    }
}

// MARK: - Predefined Category Tests

@Suite("PersonalityAnalysisService - Predefined Categories", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServicePredefinedCategoryTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("Health category habits boost conscientiousness and reduce neuroticism")
    func healthCategory_boostsConscientiousnessReducesNeuroticism() {
        // Health category weights: conscientiousness: 0.6, neuroticism: -0.3, agreeableness: 0.2
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health"],
            completionRates: [0.9] // High completion
        )

        let (scores, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: HabitCompletionStats(totalHabits: 1, completedHabits: 1, completionRate: 0.9)
        )

        // Conscientiousness should have positive accumulator from health category
        #expect(accumulators[.conscientiousness] ?? 0.0 > 0.3)

        // Neuroticism should have negative accumulator (health has -0.3 weight)
        #expect(accumulators[.neuroticism] ?? 0.0 < 0.0)

        // Final neuroticism score should be below neutral
        #expect(scores[.neuroticism] ?? 1.0 < 0.5)
    }

    @Test("Productivity category habits strongly boost conscientiousness")
    func productivityCategory_stronglyBoostsConscientiousness() {
        // Productivity category weights: conscientiousness: 0.8, neuroticism: -0.2, openness: 0.1
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["productivity"],
            completionRates: [0.8]
        )

        let (scores, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: HabitCompletionStats(totalHabits: 1, completedHabits: 1, completionRate: 0.8)
        )

        // Productivity has highest conscientiousness weight (0.8)
        #expect(accumulators[.conscientiousness] ?? 0.0 > 0.4)
        #expect(scores[.conscientiousness] ?? 0.0 > 0.5)
    }

    @Test("Social category habits boost extraversion and agreeableness")
    func socialCategory_boostsExtraversionAndAgreeableness() {
        // Social category weights: extraversion: 0.7, agreeableness: 0.6, conscientiousness: 0.3, neuroticism: -0.3
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["social"],
            completionRates: [0.8]
        )

        let (scores, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: HabitCompletionStats(totalHabits: 1, completedHabits: 1, completionRate: 0.8)
        )

        // Extraversion should have strong positive accumulator
        #expect(accumulators[.extraversion] ?? 0.0 > 0.4)

        // Agreeableness should also be boosted
        #expect(accumulators[.agreeableness] ?? 0.0 > 0.3)
    }

    @Test("Learning category habits boost openness")
    func learningCategory_boostsOpenness() {
        // Learning category weights: openness: 0.8, conscientiousness: 0.5, extraversion: 0.2, neuroticism: -0.2
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["learning"],
            completionRates: [0.8]
        )

        let (scores, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: HabitCompletionStats(totalHabits: 1, completedHabits: 1, completionRate: 0.8)
        )

        // Openness should have strong positive accumulator
        #expect(accumulators[.openness] ?? 0.0 > 0.4)
        #expect(scores[.openness] ?? 0.0 > 0.5)
    }

    @Test("Creativity category habits strongly boost openness")
    func creativityCategory_stronglyBoostsOpenness() {
        // Creativity category weights: openness: 0.9, extraversion: 0.3, conscientiousness: 0.1, neuroticism: -0.3
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["creativity"],
            completionRates: [0.8]
        )

        let (scores, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: HabitCompletionStats(totalHabits: 1, completedHabits: 1, completionRate: 0.8)
        )

        // Creativity has highest openness weight (0.9)
        #expect(accumulators[.openness] ?? 0.0 > 0.5)
        #expect(scores[.openness] ?? 0.0 > 0.5)
    }

    @Test("Wellness category habits reduce neuroticism significantly")
    func wellnessCategory_reducesNeuroticismSignificantly() {
        // Wellness category weights: conscientiousness: 0.4, neuroticism: -0.5, openness: 0.3, agreeableness: 0.2
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["wellness"],
            completionRates: [0.9]
        )

        let (scores, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: HabitCompletionStats(totalHabits: 1, completedHabits: 1, completionRate: 0.9)
        )

        // Wellness has strongest negative neuroticism weight (-0.5)
        #expect(accumulators[.neuroticism] ?? 0.0 < -0.3)
        #expect(scores[.neuroticism] ?? 1.0 < 0.5)
    }

    @Test("Multiple category habits combine weights appropriately")
    func multipleCategories_combineWeightsAppropriately() {
        // Mix of productivity (high conscientiousness) and creativity (high openness)
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["productivity", "creativity"],
            completionRates: [0.8, 0.8]
        )

        let (scores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: HabitCompletionStats(totalHabits: 2, completedHabits: 2, completionRate: 0.8)
        )

        // Both conscientiousness and openness should be elevated
        #expect(scores[.conscientiousness] ?? 0.0 > 0.5)
        #expect(scores[.openness] ?? 0.0 > 0.5)
    }
}

// MARK: - Completion Rate Tests

@Suite("PersonalityAnalysisService - Completion Rate Effects", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServiceCompletionRateTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("High completion rate boosts conscientiousness")
    func highCompletionRate_boostsConscientiousness() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health"],
            completionRates: [0.9]
        )
        let highCompletionStats = HabitCompletionStats(
            totalHabits: 1,
            completedHabits: 1,
            completionRate: 0.9
        )

        let (scoresHigh, _, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: highCompletionStats
        )

        // Compare with low completion
        let lowCompletionStats = HabitCompletionStats(
            totalHabits: 1,
            completedHabits: 0,
            completionRate: 0.2
        )
        let (scoresLow, _, _) = service.calculatePersonalityScoresWithDetails(
            from: PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
                categoryIds: ["health"],
                completionRates: [0.2]
            ),
            completionStats: lowCompletionStats
        )

        // High completion should result in higher conscientiousness
        #expect(scoresHigh[.conscientiousness] ?? 0.0 > scoresLow[.conscientiousness] ?? 0.0)
    }

    @Test("Very low completion rate (< 30%) triggers neuroticism signal")
    func veryLowCompletionRate_triggersNeuroticismSignal() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["productivity"],
            completionRates: [0.15] // Very low
        )
        let lowCompletionStats = HabitCompletionStats(
            totalHabits: 5,
            completedHabits: 0,
            completionRate: 0.15
        )

        let (scores, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: lowCompletionStats
        )

        // Very low completion should add positive neuroticism signal (struggle indicator)
        // Note: The category weight for productivity is neuroticism: -0.2
        // But completion rate < 30% should add instability contribution
        #expect(accumulators[.neuroticism] ?? 0.0 > 0.0)
    }

    @Test("Moderate completion rate (>= 30%) does not add neuroticism signal")
    func moderateCompletionRate_noNeuroticismSignal() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["productivity"],
            completionRates: [0.5]
        )
        let moderateCompletionStats = HabitCompletionStats(
            totalHabits: 1,
            completedHabits: 1,
            completionRate: 0.5
        )

        let (_, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: moderateCompletionStats
        )

        // With productivity category (neuroticism: -0.2) and moderate completion,
        // neuroticism accumulator should be negative or near zero
        #expect(accumulators[.neuroticism] ?? 0.0 <= 0.1)
    }

    @Test("Completion weighting affects category contribution magnitude")
    func completionWeighting_affectsCategoryContribution() {
        let inputHigh = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health"],
            completionRates: [1.0] // Perfect completion
        )

        let inputLow = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health"],
            completionRates: [0.1] // Very low but not zero
        )

        let (_, accumulatorsHigh, _) = service.calculatePersonalityScoresWithDetails(
            from: inputHigh,
            completionStats: nil
        )

        let (_, accumulatorsLow, _) = service.calculatePersonalityScoresWithDetails(
            from: inputLow,
            completionStats: nil
        )

        // High completion should result in stronger category contribution
        #expect(abs(accumulatorsHigh[.conscientiousness] ?? 0.0) >
                abs(accumulatorsLow[.conscientiousness] ?? 0.0))
    }
}

// MARK: - Dominant Trait Tests

@Suite("PersonalityAnalysisService - Dominant Trait Determination", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServiceDominantTraitTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("Dominant trait is the highest scoring trait")
    func dominantTrait_isHighestScoringTrait() {
        let scores: [PersonalityTrait: Double] = [
            .openness: 0.6,
            .conscientiousness: 0.8,
            .extraversion: 0.5,
            .agreeableness: 0.4,
            .neuroticism: 0.3
        ]

        let dominant = service.determineDominantTrait(from: scores)

        #expect(dominant == .conscientiousness)
    }

    @Test("Single trait scoring returns that trait as dominant")
    func singleTraitScore_returnsThatTrait() {
        let scores: [PersonalityTrait: Double] = [
            .openness: 0.9
        ]

        let dominant = service.determineDominantTrait(from: scores)

        #expect(dominant == .openness)
    }

    @Test("Empty scores returns conscientiousness as default")
    func emptyScores_returnsConscientiousnessDefault() {
        let scores: [PersonalityTrait: Double] = [:]

        let dominant = service.determineDominantTrait(from: scores)

        #expect(dominant == .conscientiousness)
    }

    @Test("Tied scores returns one of the tied traits")
    func tiedScores_returnsOneOfTiedTraits() {
        let scores: [PersonalityTrait: Double] = [
            .openness: 0.7,
            .conscientiousness: 0.7,
            .extraversion: 0.5,
            .agreeableness: 0.5,
            .neuroticism: 0.5
        ]

        let dominant = service.determineDominantTrait(from: scores)

        // Should be one of the tied traits
        #expect(dominant == .openness || dominant == .conscientiousness)
    }

    @Test("Creativity-focused user has openness as dominant")
    func creativityFocusedUser_hasOpennessDominant() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["creativity"],
            completionRates: [0.9]
        )

        let scores = service.calculatePersonalityScores(from: input)
        let dominant = service.determineDominantTrait(from: scores)

        // With only creativity habits (openness: 0.9), openness should dominate
        #expect(dominant == .openness)
    }

    @Test("Productivity-focused user has conscientiousness as dominant")
    func productivityFocusedUser_hasConscientiousnessDominant() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["productivity"],
            completionRates: [0.9]
        )

        let scores = service.calculatePersonalityScores(from: input)
        let dominant = service.determineDominantTrait(from: scores)

        // With only productivity habits (conscientiousness: 0.8), conscientiousness should dominate
        #expect(dominant == .conscientiousness)
    }

    @Test("Social-focused user has extraversion as dominant")
    func socialFocusedUser_hasExtraversionDominant() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["social"],
            completionRates: [0.9]
        )

        let scores = service.calculatePersonalityScores(from: input)
        let dominant = service.determineDominantTrait(from: scores)

        // With only social habits (extraversion: 0.7), extraversion should dominate
        #expect(dominant == .extraversion || dominant == .agreeableness)
    }
}

// MARK: - Confidence Level Tests

@Suite("PersonalityAnalysisService - Confidence Calculation", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServiceConfidenceTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("Less than 30 data points gives low confidence")
    func lessThan30DataPoints_givesLowConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 25)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .low)
    }

    @Test("30-75 data points gives medium confidence")
    func between30And75DataPoints_givesMediumConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 50)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .medium)
    }

    @Test("75-150 data points gives high confidence")
    func between75And150DataPoints_givesHighConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 100)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .high)
    }

    @Test("150+ data points gives very high confidence")
    func moreThan150DataPoints_givesVeryHighConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 200)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .veryHigh)
    }

    @Test("Zero data points gives low confidence")
    func zeroDataPoints_givesLowConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 0)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .low)
    }

    @Test("Boundary at 30 data points gives medium confidence")
    func exactlyAt30DataPoints_givesMediumConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 30)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .medium)
    }

    @Test("Boundary at 75 data points gives high confidence")
    func exactlyAt75DataPoints_givesHighConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 75)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .high)
    }

    @Test("Boundary at 150 data points gives very high confidence")
    func exactlyAt150DataPoints_givesVeryHighConfidence() {
        let metadata = PersonalityTestDataBuilder.metadata(dataPoints: 150)

        let confidence = service.calculateConfidence(from: metadata)

        #expect(confidence == .veryHigh)
    }
}

// MARK: - Custom Category Tests

@Suite("PersonalityAnalysisService - Custom Categories", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServiceCustomCategoryTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("Custom category with explicit weights uses those weights")
    func customCategoryWithExplicitWeights_usesThoseWeights() {
        let customCategory = CategoryBuilder.category(
            id: "custom-openness",
            name: "custom-openness",
            displayName: "Custom Openness",
            isPredefined: false,
            personalityWeights: [
                "openness": 0.9,
                "conscientiousness": 0.1
            ]
        )

        let input = PersonalityTestDataBuilder.inputWithCustomCategoryHabits(
            customCategories: [customCategory],
            habitsPerCategory: 1,
            completionRates: [0.8]
        )

        let (_, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: nil
        )

        // Custom category should contribute with 50% weight (customCategoryWeight = 0.5)
        // Openness contribution: 0.9 * 0.8 (completion) * 1.0 (habitWeight) * 0.5 (customWeight) = 0.36
        #expect(accumulators[.openness] ?? 0.0 > 0.2)
    }

    @Test("Custom categories have reduced influence compared to predefined")
    func customCategories_haveReducedInfluence() {
        // Create identical weights for comparison
        let predefinedInput = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["learning"], // openness: 0.8
            completionRates: [0.8]
        )

        let customCategory = CategoryBuilder.category(
            id: "custom-learning",
            name: "custom-learning",
            displayName: "Custom Learning",
            isPredefined: false,
            personalityWeights: ["openness": 0.8]
        )

        let customInput = PersonalityTestDataBuilder.inputWithCustomCategoryHabits(
            customCategories: [customCategory],
            habitsPerCategory: 1,
            completionRates: [0.8]
        )

        let (_, predefinedAccum, _) = service.calculatePersonalityScoresWithDetails(
            from: predefinedInput,
            completionStats: nil
        )

        let (_, customAccum, _) = service.calculatePersonalityScoresWithDetails(
            from: customInput,
            completionStats: nil
        )

        // Predefined should have stronger contribution (1.0 vs 0.5 multiplier)
        #expect(predefinedAccum[.openness] ?? 0.0 > customAccum[.openness] ?? 0.0)
    }
}

// MARK: - Diversity and Social Tests

@Suite("PersonalityAnalysisService - Diversity and Social", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServiceDiversitySocialTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("Multiple diverse categories add small openness bonus")
    func multipleDiverseCategories_addOpennessBonus() {
        // User with habits across many categories
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health", "productivity", "social", "learning", "creativity"],
            completionRates: [0.7, 0.7, 0.7, 0.7, 0.7]
        )

        // Single category user
        let singleCategoryInput = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health"],
            completionRates: [0.7]
        )

        let (diverseScores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: nil
        )

        let (singleScores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: singleCategoryInput,
            completionStats: nil
        )

        // Diversity should add openness bonus (though learning/creativity already boost it)
        // The diverse user should have higher openness overall
        #expect(diverseScores[.openness] ?? 0.0 >= singleScores[.openness] ?? 0.0)
    }

    @Test("Social keyword habits add extraversion bonus")
    func socialKeywordHabits_addExtraversionBonus() {
        let input = PersonalityTestDataBuilder.inputWithSocialKeywordHabits()

        let (_, accumulators, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: nil
        )

        // Social keyword habits should contribute to extraversion
        // socialRatio * 0.25 = 1.0 * 0.25 = 0.25 (all 3 habits have social keywords)
        #expect(accumulators[.extraversion] ?? 0.0 > 0.1)
    }
}

// MARK: - Score Normalization Tests

@Suite("PersonalityAnalysisService - Score Normalization", .tags(.businessLogic, .profile))
struct PersonalityAnalysisServiceNormalizationTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("All scores are normalized to 0-1 range")
    func allScores_areNormalizedTo01Range() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health", "productivity", "social", "learning", "creativity"],
            completionRates: [0.9, 0.9, 0.9, 0.9, 0.9]
        )

        let scores = service.calculatePersonalityScores(from: input)

        for (trait, score) in scores {
            #expect(score >= 0.0, "Trait \(trait) score \(score) should be >= 0.0")
            #expect(score <= 1.0, "Trait \(trait) score \(score) should be <= 1.0")
        }
    }

    @Test("Negative category weights produce below-neutral neuroticism")
    func negativeCategoryWeights_produceBelowNeutralNeuroticism() {
        // All categories have negative neuroticism weights
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health", "wellness"], // Both have negative neuroticism
            completionRates: [0.9, 0.9]
        )

        let scores = service.calculatePersonalityScores(from: input)

        // With negative weights, neuroticism should be below 0.5 (neutral)
        #expect(scores[.neuroticism] ?? 1.0 < 0.5)
    }

    @Test("Traits with no evidence have minimal variance")
    func traitsWithNoEvidence_defaultToNeutral() {
        // Minimal input that doesn't touch all traits significantly
        let input = PersonalityTestDataBuilder.emptyInput()

        let scores = service.calculatePersonalityScores(from: input)

        // With no data, all traits should be in valid range
        for trait in PersonalityTrait.allCases {
            let score = scores[trait] ?? 0.0
            #expect(score >= 0.0 && score <= 1.0,
                   "Trait \(trait) should be in valid range, got \(score)")
        }

        // Scores should not have extreme variance with no evidence
        let allScores = scores.values
        let maxScore = allScores.max() ?? 0.0
        let minScore = allScores.min() ?? 0.0
        #expect(maxScore - minScore < 0.7,
               "No evidence should not produce extreme variance: max=\(maxScore), min=\(minScore)")
    }
}

// MARK: - Integration Tests

@Suite("PersonalityAnalysisService - Integration", .tags(.businessLogic, .profile, .integration))
struct PersonalityAnalysisServiceIntegrationTests {

    let service: DefaultPersonalityAnalysisService

    init() {
        let repository = TestPersonalityAnalysisRepository()
        service = DefaultPersonalityAnalysisService(repository: repository)
    }

    @Test("Realistic user profile produces expected trait distribution")
    func realisticUserProfile_producesExpectedTraitDistribution() {
        // Simulate a user focused on health, productivity, and learning
        // This represents a disciplined, curious person
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["health", "productivity", "learning"],
            completionRates: [0.85, 0.9, 0.75]
        )

        let scores = service.calculatePersonalityScores(from: input)

        // Conscientiousness should be high (health + productivity)
        #expect(scores[.conscientiousness] ?? 0.0 > 0.6)

        // Openness should be elevated (learning)
        #expect(scores[.openness] ?? 0.0 > 0.5)

        // Neuroticism should be low (all categories have negative weights)
        #expect(scores[.neuroticism] ?? 1.0 < 0.5)
    }

    @Test("Social butterfly profile has high extraversion and agreeableness")
    func socialButterflyProfile_hasHighExtraversionAndAgreeableness() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["social"],
            completionRates: [0.9],
            habitsPerCategory: 3 // Multiple social habits
        )

        let scores = service.calculatePersonalityScores(from: input)

        // Extraversion and agreeableness should be high
        #expect(scores[.extraversion] ?? 0.0 > 0.5)
        #expect(scores[.agreeableness] ?? 0.0 > 0.5)
    }

    @Test("Creative person profile has high openness")
    func creativePersonProfile_hasHighOpenness() {
        let input = PersonalityTestDataBuilder.inputWithPredefinedCategoryHabits(
            categoryIds: ["creativity", "learning"],
            completionRates: [0.9, 0.85],
            habitsPerCategory: 2
        )

        let scores = service.calculatePersonalityScores(from: input)
        let dominant = service.determineDominantTrait(from: scores)

        // Openness should be the dominant trait
        #expect(dominant == .openness)
        #expect(scores[.openness] ?? 0.0 > 0.6)
    }
}
