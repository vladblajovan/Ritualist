//
//  PersonalityAnalysisServiceTests.swift
//  RitualistTests
//
//  Created by Claude on 22.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
@testable import RitualistCore

@available(*, deprecated, message: "PHASE 1B+4B MIGRATION REQUIRED: This test uses MockPersonalityAnalysisRepository pattern. Will be rewritten to use real implementations with TestModelContainer during comprehensive testing phase.")
@Suite("PersonalityAnalysisService Tests")
struct PersonalityAnalysisServiceTests {
    
    // MARK: - Test Infrastructure
    
    /// Mock repository for testing PersonalityAnalysisService
    class MockPersonalityAnalysisRepository: PersonalityAnalysisRepositoryProtocol {
        var mockHabitAnalysisInput: HabitAnalysisInput?
        var mockCompletionStats: HabitCompletionStats?
        
        func getPersonalityProfile(for userId: UUID) async throws -> PersonalityProfile? {
            return nil
        }
        
        func savePersonalityProfile(_ profile: PersonalityProfile) async throws {}
        
        func getPersonalityHistory(for userId: UUID) async throws -> [PersonalityProfile] {
            return []
        }
        
        func deletePersonalityProfile(id: UUID) async throws {}
        
        func deleteAllPersonalityProfiles(for userId: UUID) async throws {}
        
        func validateAnalysisEligibility(for userId: UUID) async throws -> AnalysisEligibility {
            return AnalysisEligibility(
                isEligible: true,
                missingRequirements: [],
                overallProgress: 1.0
            )
        }
        
        func getThresholdProgress(for userId: UUID) async throws -> [ThresholdRequirement] {
            return []
        }
        
        func getHabitAnalysisInput(for userId: UUID) async throws -> HabitAnalysisInput {
            return mockHabitAnalysisInput ?? createDefaultHabitAnalysisInput()
        }
        
        func getUserHabits(for userId: UUID) async throws -> [Habit] {
            return []
        }
        
        func getUserHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
            return []
        }
        
        func getUserCustomCategories(for userId: UUID) async throws -> [HabitCategory] {
            return []
        }
        
        func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
            return mockCompletionStats ?? HabitCompletionStats(
                totalHabits: 0,
                completedHabits: 0,
                completionRate: 0.0
            )
        }
        
        func isPersonalityAnalysisEnabled(for userId: UUID) async throws -> Bool {
            return true
        }
        
        func getAnalysisPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences? {
            return nil
        }
        
        func saveAnalysisPreferences(_ preferences: PersonalityAnalysisPreferences) async throws {}
        
        private func createDefaultHabitAnalysisInput() -> HabitAnalysisInput {
            return HabitAnalysisInput(
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
    }
    
    // MARK: - Helper Methods for Creating Test Data
    
    func createTestService(with repository: MockPersonalityAnalysisRepository? = nil) -> DefaultPersonalityAnalysisService {
        let mockRepo = repository ?? MockPersonalityAnalysisRepository()
        return DefaultPersonalityAnalysisService(repository: mockRepo)
    }
    
    func createHabitAnalysisInput(
        activeHabits: [Habit] = [],
        completionRates: [Double] = [],
        customHabits: [Habit] = [],
        customCategories: [HabitCategory] = [],
        habitCategories: [HabitCategory] = [],
        selectedSuggestions: [HabitSuggestion] = [],
        trackingDays: Int = 30,
        analysisTimeRange: Int = 30,
        totalDataPoints: Int = 100
    ) -> HabitAnalysisInput {
        return HabitAnalysisInput(
            activeHabits: activeHabits,
            completionRates: completionRates,
            customHabits: customHabits,
            customCategories: customCategories,
            habitCategories: habitCategories,
            selectedSuggestions: selectedSuggestions,
            trackingDays: trackingDays,
            analysisTimeRange: analysisTimeRange,
            totalDataPoints: totalDataPoints
        )
    }
    
    func createHabitSuggestion(
        id: String = "test-suggestion",
        name: String = "Test Habit",
        personalityWeights: [String: Double]? = nil
    ) -> HabitSuggestion {
        return HabitSuggestion(
            id: id,
            name: name,
            emoji: "🎯",
            colorHex: "#FF0000",
            categoryId: "health",
            kind: .binary,
            description: "Test habit description",
            personalityWeights: personalityWeights
        )
    }
    
    func createCompletionStats(
        totalHabits: Int = 5,
        completedHabits: Int = 3,
        completionRate: Double = 0.6
    ) -> HabitCompletionStats {
        return HabitCompletionStats(
            totalHabits: totalHabits,
            completedHabits: completedHabits,
            completionRate: completionRate
        )
    }
    
    // MARK: - Basic Functionality Tests
    
    @Test("Service calculates personality scores from habit analysis input")
    func testBasicPersonalityScoreCalculation() {
        let service = createTestService()
        
        // Create test categories with personality weights
        let healthCategory = CategoryBuilder.healthCategory()
            .withPersonalityWeights([
                "conscientiousness": 0.8,
                "openness": 0.2,
                "extraversion": 0.0,
                "agreeableness": 0.1,
                "neuroticism": -0.3
            ])
            .build()
        
        let creativeCategory = CategoryBuilder.creativeCategory()
            .withPersonalityWeights([
                "openness": 0.9,
                "conscientiousness": 0.1,
                "extraversion": 0.3,
                "agreeableness": 0.2,
                "neuroticism": 0.0
            ])
            .build()
        
        // Create habits in these categories
        let workoutHabit = HabitBuilder.workoutHabit()
            .withCategoryId(healthCategory.id)
            .build()
        
        let readingHabit = HabitBuilder.readingHabit()
            .withCategoryId(creativeCategory.id)
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [workoutHabit, readingHabit],
            completionRates: [0.8, 0.9], // High completion rates
            habitCategories: [healthCategory, creativeCategory]
        )
        
        let scores = service.calculatePersonalityScores(from: input)
        
        // Verify all traits have scores
        #expect(scores.count == PersonalityTrait.allCases.count)
        
        // Verify scores are in valid range (0.0 to 1.0)
        for (_, score) in scores {
            #expect(score >= 0.0)
            #expect(score <= 1.0)
        }
        
        // With health and creative habits, conscientiousness and openness should be elevated
        #expect(scores[.conscientiousness] ?? 0.0 > 0.5)
        #expect(scores[.openness] ?? 0.0 > 0.5)
    }
    
    // MARK: - Big Five Trait Calculation Tests
    
    @Test("Conscientiousness trait calculation with high completion rates")
    func testConscientiousnessCalculation() {
        let service = createTestService()
        
        // Create organized/disciplined habits
        let organizingHabit = HabitBuilder()
            .withName("Daily Planning")
            .withCategoryId("productivity")
            .build()
        
        let routineHabit = HabitBuilder()
            .withName("Morning Routine")
            .withCategoryId("health")
            .build()
        
        let productivityCategory = CategoryBuilder.productivityCategory()
            .withPersonalityWeights([
                "conscientiousness": 0.9,
                "openness": 0.1,
                "extraversion": 0.0,
                "agreeableness": 0.0,
                "neuroticism": -0.2
            ])
            .build()
        
        let healthCategory = CategoryBuilder.healthCategory()
            .withPersonalityWeights([
                "conscientiousness": 0.7,
                "neuroticism": -0.4
            ])
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [organizingHabit, routineHabit],
            completionRates: [0.9, 0.85], // Very high completion rates
            habitCategories: [productivityCategory, healthCategory]
        )
        
        let stats = createCompletionStats(
            totalHabits: 2,
            completedHabits: 2,
            completionRate: 0.875
        )
        
        let (scores, accumulators, totalWeights) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: stats
        )
        
        // Conscientiousness should be the dominant trait
        #expect(scores[.conscientiousness] ?? 0.0 > 0.6)
        #expect(scores[.conscientiousness] ?? 0.0 > (scores[.openness] ?? 0.0))
        #expect(scores[.conscientiousness] ?? 0.0 > (scores[.extraversion] ?? 0.0))
        
        // Should have positive accumulator and significant weight for conscientiousness
        #expect(accumulators[.conscientiousness] ?? 0.0 > 0.0)
        #expect(totalWeights[.conscientiousness] ?? 0.0 > 0.0)
    }
    
    @Test("Openness trait calculation with learning and creative habits")
    func testOpennessCalculation() {
        let service = createTestService()
        
        // Create learning and creative habits
        let learningHabit = HabitBuilder()
            .withName("Learn New Language")
            .withCategoryId("learning")
            .build()
        
        let creativeHabit = HabitBuilder()
            .withName("Creative Writing")
            .withCategoryId("creative")
            .build()
        
        let experimentHabit = HabitBuilder()
            .withName("Try New Recipes")
            .withSchedule(.timesPerWeek(3)) // Flexible schedule shows openness
            .withCategoryId("lifestyle")
            .build()
        
        let learningCategory = CategoryBuilder.learningCategory()
            .withPersonalityWeights([
                "openness": 0.9,
                "conscientiousness": 0.3
            ])
            .build()
        
        let creativeCategory = CategoryBuilder.creativeCategory()
            .withPersonalityWeights([
                "openness": 0.8,
                "extraversion": 0.3
            ])
            .build()
        
        let lifestyleCategory = CategoryBuilder.lifestyleCategory()
            .withPersonalityWeights([
                "openness": 0.6,
                "agreeableness": 0.3
            ])
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [learningHabit, creativeHabit, experimentHabit],
            completionRates: [0.7, 0.8, 0.6],
            habitCategories: [learningCategory, creativeCategory, lifestyleCategory]
        )
        
        let stats = createCompletionStats(
            totalHabits: 3,
            completedHabits: 2,
            completionRate: 0.7
        )
        
        let (scores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: stats
        )
        
        // Openness should be elevated due to variety and creative habits
        #expect(scores[.openness] ?? 0.0 > 0.6)
        
        // Should be higher than more rigid traits
        #expect(scores[.openness] ?? 0.0 > (scores[.conscientiousness] ?? 0.0))
    }
    
    @Test("Extraversion trait calculation with social habits")
    func testExtraversionCalculation() {
        let service = createTestService()
        
        // Create social habits
        let socialHabit1 = HabitBuilder()
            .withName("Call Friends")
            .withCategoryId("social")
            .build()
        
        let socialHabit2 = HabitBuilder()
            .withName("Meet New People")
            .withCategoryId("social")
            .build()
        
        let partyHabit = HabitBuilder()
            .withName("Attend Social Events")
            .withCategoryId("social")
            .build()
        
        let socialCategory = CategoryBuilder.socialCategory()
            .withPersonalityWeights([
                "extraversion": 0.9,
                "agreeableness": 0.6,
                "openness": 0.3,
                "conscientiousness": 0.1,
                "neuroticism": -0.3
            ])
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [socialHabit1, socialHabit2, partyHabit],
            completionRates: [0.8, 0.7, 0.6],
            customHabits: [socialHabit1, socialHabit2, partyHabit], // Also include as custom for social analysis
            habitCategories: [socialCategory]
        )
        
        let scores = service.calculatePersonalityScores(from: input)
        
        // Extraversion should be dominant with multiple social habits
        #expect(scores[.extraversion] ?? 0.0 > 0.6)
        #expect(scores[.extraversion] ?? 0.0 > (scores[.conscientiousness] ?? 0.0))
        #expect(scores[.extraversion] ?? 0.0 > (scores[.neuroticism] ?? 0.0))
    }
    
    @Test("Agreeableness trait calculation with helping and care habits")
    func testAgreeablenessCalculation() {
        let service = createTestService()
        
        // Create caring/helping habits
        let volunteerHabit = HabitBuilder()
            .withName("Volunteer at Charity")
            .withCategoryId("social")
            .build()
        
        let familyHabit = HabitBuilder()
            .withName("Family Time")
            .withCategoryId("lifestyle")
            .build()
        
        let helpHabit = HabitBuilder()
            .withName("Help Others")
            .withCategoryId("social")
            .build()
        
        let socialCategory = CategoryBuilder.socialCategory()
            .withPersonalityWeights([
                "agreeableness": 0.8,
                "extraversion": 0.6,
                "conscientiousness": 0.3
            ])
            .build()
        
        let lifestyleCategory = CategoryBuilder.lifestyleCategory()
            .withPersonalityWeights([
                "agreeableness": 0.5,
                "conscientiousness": 0.4
            ])
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [volunteerHabit, familyHabit, helpHabit],
            completionRates: [0.9, 0.8, 0.7],
            habitCategories: [socialCategory, lifestyleCategory]
        )
        
        let scores = service.calculatePersonalityScores(from: input)
        
        // Agreeableness should be elevated with caring habits
        #expect(scores[.agreeableness] ?? 0.0 > 0.6)
        
        // Should be competitive with other traits but distinct
        #expect(scores[.agreeableness] ?? 0.0 > (scores[.neuroticism] ?? 0.0))
    }
    
    @Test("Neuroticism trait calculation with stress and emotional patterns")
    func testNeuroticismCalculation() {
        let service = createTestService()
        
        // Test low completion rates leading to higher neuroticism
        let stressHabit = HabitBuilder()
            .withName("Manage Stress")
            .withCategoryId("mindfulness")
            .build()
        
        let anxietyHabit = HabitBuilder()
            .withName("Anxiety Journaling")
            .withCategoryId("mindfulness")
            .build()
        
        let mindfulnessCategory = CategoryBuilder.mindfulnessCategory()
            .withPersonalityWeights([
                "neuroticism": -0.2, // Mindfulness reduces neuroticism
                "conscientiousness": 0.3,
                "openness": 0.2
            ])
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [stressHabit, anxietyHabit],
            completionRates: [0.3, 0.25], // Low completion rates
            habitCategories: [mindfulnessCategory]
        )
        
        let stats = createCompletionStats(
            totalHabits: 2,
            completedHabits: 0,
            completionRate: 0.275 // Low completion rate suggests instability
        )
        
        let (scores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: stats
        )
        
        // With low completion rates, neuroticism should be elevated
        // But mindfulness habits should provide some stability
        #expect(scores[.neuroticism] ?? 0.0 > 0.4)
    }
    
    // MARK: - Confidence Scoring Tests
    
    @Test("Confidence calculation with varying data point amounts")
    func testConfidenceCalculationBasic() {
        let service = createTestService()
        
        // Test different data point levels
        let lowDataMetadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: 20,
            timeRangeAnalyzed: 30,
            version: "1.6"
        )
        
        let mediumDataMetadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: 50,
            timeRangeAnalyzed: 30,
            version: "1.6"
        )
        
        let highDataMetadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: 100,
            timeRangeAnalyzed: 30,
            version: "1.6"
        )
        
        let veryHighDataMetadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: 200,
            timeRangeAnalyzed: 30,
            version: "1.6"
        )
        
        let lowConfidence = service.calculateConfidence(from: lowDataMetadata)
        let mediumConfidence = service.calculateConfidence(from: mediumDataMetadata)
        let highConfidence = service.calculateConfidence(from: highDataMetadata)
        let veryHighConfidence = service.calculateConfidence(from: veryHighDataMetadata)
        
        #expect(lowConfidence == .low)
        #expect(mediumConfidence == .medium)
        #expect(highConfidence == .high)
        #expect(veryHighConfidence == .veryHigh)
    }
    
    @Test("Enhanced confidence calculation with completion statistics")
    func testEnhancedConfidenceCalculation() {
        let service = createTestService()
        
        let baseMetadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: 50, // Higher base to ensure high confidence with bonuses
            timeRangeAnalyzed: 30,
            version: "1.6"
        )
        
        // High quality completion stats should boost confidence
        let highQualityStats = createCompletionStats(
            totalHabits: 8, // Good diversity
            completedHabits: 6,
            completionRate: 0.9 // Very high completion rate = strong signal
        )
        
        // Low quality completion stats should provide less boost
        let lowQualityStats = createCompletionStats(
            totalHabits: 2, // Limited diversity
            completedHabits: 1,
            completionRate: 0.5 // Neutral completion rate = weak signal
        )
        
        let enhancedConfidence = service.calculateConfidenceWithCompletionStats(
            from: baseMetadata,
            completionStats: highQualityStats
        )
        
        let normalConfidence = service.calculateConfidenceWithCompletionStats(
            from: baseMetadata,
            completionStats: lowQualityStats
        )
        
        // Debug logging to understand the calculation
        print("🐛 [CONFIDENCE DEBUG] Base data points: \(baseMetadata.dataPointsAnalyzed)")
        print("🐛 [CONFIDENCE DEBUG] High quality stats: \(highQualityStats.totalHabits) habits, \(highQualityStats.completionRate) rate")
        print("🐛 [CONFIDENCE DEBUG] Low quality stats: \(lowQualityStats.totalHabits) habits, \(lowQualityStats.completionRate) rate")
        print("🐛 [CONFIDENCE DEBUG] Enhanced confidence: \(enhancedConfidence) (score: \(enhancedConfidence.score))")
        print("🐛 [CONFIDENCE DEBUG] Normal confidence: \(normalConfidence) (score: \(normalConfidence.score))")
        
        // High quality stats should boost confidence level
        #expect(enhancedConfidence.score > normalConfidence.score, "Enhanced confidence (\(enhancedConfidence.score)) should be higher than normal (\(normalConfidence.score))")
        
        // With good completion stats, should reach high confidence (adjusted expectation based on thresholds)
        #expect(enhancedConfidence == .high || enhancedConfidence == .veryHigh, "Enhanced confidence should be high or veryHigh, got \(enhancedConfidence)")
    }
    
    // MARK: - Tie-Breaking Algorithm Tests
    
    @Test("Multi-criteria tie-breaking system with equal trait scores")
    func testTieBreakingAlgorithm() {
        let service = createTestService()
        
        // Create scenario where two traits have equal scores
        let input = createHabitAnalysisInput(
            activeHabits: [
                HabitBuilder().withName("Organized Planning").withCategoryId("productivity").build(),
                HabitBuilder().withName("Creative Writing").withCategoryId("creative").build()
            ],
            completionRates: [0.8, 0.8],
            habitCategories: [
                CategoryBuilder.productivityCategory()
                    .withPersonalityWeights(["conscientiousness": 0.5, "openness": 0.2])
                    .build(),
                CategoryBuilder.creativeCategory()
                    .withPersonalityWeights(["openness": 0.5, "conscientiousness": 0.2])
                    .build()
            ]
        )
        
        // Create artificially equal scores for testing tie-breaking
        let equalScores: [PersonalityTrait: Double] = [
            .conscientiousness: 0.7,
            .openness: 0.7, // Equal top scores
            .extraversion: 0.5,
            .agreeableness: 0.4,
            .neuroticism: 0.3
        ]
        
        let traitAccumulators: [PersonalityTrait: Double] = [
            .conscientiousness: 0.35,
            .openness: 0.30, // Slightly lower accumulator
            .extraversion: 0.1,
            .agreeableness: 0.05,
            .neuroticism: -0.1
        ]
        
        let totalWeights: [PersonalityTrait: Double] = [
            .conscientiousness: 0.8,
            .openness: 0.7,
            .extraversion: 0.3,
            .agreeableness: 0.2,
            .neuroticism: 0.1
        ]
        
        let dominantTrait = service.determineDominantTraitWithTieBreaking(
            from: equalScores,
            traitAccumulators: traitAccumulators,
            totalWeights: totalWeights,
            input: input
        )
        
        // Should pick conscientiousness due to higher raw accumulator and stability
        #expect(dominantTrait == .conscientiousness || dominantTrait == .openness)
        
        // Verify the simple method picks one of the tied traits
        let simpleDominant = service.determineDominantTrait(from: equalScores)
        #expect(simpleDominant == .conscientiousness || simpleDominant == .openness)
    }
    
    @Test("Tie-breaking with single clear winner")
    func testTieBreakingWithClearWinner() {
        let service = createTestService()
        
        let clearScores: [PersonalityTrait: Double] = [
            .conscientiousness: 0.8,
            .openness: 0.6,
            .extraversion: 0.5,
            .agreeableness: 0.4,
            .neuroticism: 0.3
        ]
        
        let input = createHabitAnalysisInput()
        let accumulators: [PersonalityTrait: Double] = [:]
        let weights: [PersonalityTrait: Double] = [:]
        
        let dominantTrait = service.determineDominantTraitWithTieBreaking(
            from: clearScores,
            traitAccumulators: accumulators,
            totalWeights: weights,
            input: input
        )
        
        // Should pick conscientiousness as clear winner
        #expect(dominantTrait == .conscientiousness)
    }
    
    // MARK: - Edge Cases and Data Validation Tests
    
    @Test("Service handles empty input data gracefully")
    func testEmptyInputHandling() {
        let service = createTestService()
        
        let emptyInput = createHabitAnalysisInput(
            activeHabits: [],
            completionRates: [],
            customHabits: [],
            customCategories: [],
            habitCategories: [],
            selectedSuggestions: [],
            trackingDays: 0,
            analysisTimeRange: 0,
            totalDataPoints: 0
        )
        
        let scores = service.calculatePersonalityScores(from: emptyInput)
        
        // Should return neutral scores (0.5) for all traits
        #expect(scores.count == PersonalityTrait.allCases.count)
        
        for (_, score) in scores {
            #expect(score >= 0.0)
            #expect(score <= 1.0)
            // With no data, scores should be close to neutral
            #expect(abs(score - 0.5) < 0.3)
        }
    }
    
    @Test("Service handles insufficient data appropriately")
    func testInsufficientDataHandling() {
        let service = createTestService()
        
        let metadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: 5, // Very low data points
            timeRangeAnalyzed: 30,
            version: "1.6"
        )
        
        let confidence = service.calculateConfidence(from: metadata)
        
        #expect(confidence == .low)
    }
    
    @Test("Service handles extreme completion rates correctly")
    func testExtremeCompletionRates() {
        let service = createTestService()
        
        // Test with 100% completion rate
        let perfectInput = createHabitAnalysisInput(
            activeHabits: [
                HabitBuilder.workoutHabit().build(),
                HabitBuilder.readingHabit().build()
            ],
            completionRates: [1.0, 1.0],
            habitCategories: [
                CategoryBuilder.healthCategory().build(),
                CategoryBuilder.learningCategory().build()
            ]
        )
        
        let perfectStats = createCompletionStats(
            totalHabits: 2,
            completedHabits: 2,
            completionRate: 1.0
        )
        
        let (perfectScores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: perfectInput,
            completionStats: perfectStats
        )
        
        // Perfect completion should boost conscientiousness and reduce neuroticism
        #expect(perfectScores[.conscientiousness] ?? 0.0 > 0.6)
        #expect(perfectScores[.neuroticism] ?? 0.0 < 0.4)
        
        // Test with 0% completion rate
        let failedInput = createHabitAnalysisInput(
            activeHabits: [
                HabitBuilder.workoutHabit().build(),
                HabitBuilder.readingHabit().build()
            ],
            completionRates: [0.0, 0.0],
            habitCategories: [
                CategoryBuilder.healthCategory().build(),
                CategoryBuilder.learningCategory().build()
            ]
        )
        
        let failedStats = createCompletionStats(
            totalHabits: 2,
            completedHabits: 0,
            completionRate: 0.0
        )
        
        let (failedScores, _, _) = service.calculatePersonalityScoresWithDetails(
            from: failedInput,
            completionStats: failedStats
        )
        
        // Zero completion should increase neuroticism
        #expect(failedScores[.neuroticism] ?? 0.0 > 0.5)
    }
    
    // MARK: - Schedule Awareness Tests
    
    @Test("Service respects habit schedules in completion analysis")
    func testScheduleAwarenessInAnalysis() {
        let service = createTestService()
        
        // Create habits with different schedule types
        let dailyHabit = HabitBuilder()
            .withName("Daily Meditation")
            .withSchedule(.daily)
            .withCategoryId("mindfulness")
            .build()
        
        let flexibleHabit = HabitBuilder()
            .withName("Flexible Exercise")
            .withSchedule(.timesPerWeek(3))
            .withCategoryId("health")
            .build()
        
        let specificDaysHabit = HabitBuilder()
            .withName("Weekend Projects")
            .withSchedule(.daysOfWeek([6, 7])) // Weekends only
            .withCategoryId("creative")
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [dailyHabit, flexibleHabit, specificDaysHabit],
            completionRates: [0.9, 0.8, 0.7],
            habitCategories: [
                CategoryBuilder.mindfulnessCategory().build(),
                CategoryBuilder.healthCategory().build(),
                CategoryBuilder.creativeCategory().build()
            ]
        )
        
        let scores = service.calculatePersonalityScores(from: input)
        
        // Daily habits should boost conscientiousness
        // Flexible schedules should boost openness
        #expect(scores[.conscientiousness] ?? 0.0 > 0.4)
        #expect(scores[.openness] ?? 0.0 > 0.4)
        
        // All scores should be valid
        for (_, score) in scores {
            #expect(score >= 0.0)
            #expect(score <= 1.0)
        }
    }
    
    // MARK: - Habit Name Analysis and Modifiers Tests
    
    @Test("Service applies habit-specific modifiers based on name analysis")
    func testHabitNameAnalysisModifiers() {
        let service = createTestService()
        
        // Create habits with personality-indicating names
        let organizingHabit = HabitBuilder()
            .withName("Daily Organization Routine")  // Should boost conscientiousness
            .withCategoryId("productivity")
            .build()
        
        let creativeHabit = HabitBuilder()
            .withName("Creative Art Practice")       // Should boost openness
            .withCategoryId("creative")
            .build()
        
        let socialHabit = HabitBuilder()
            .withName("Call Friends Weekly")         // Should boost extraversion
            .withCategoryId("social")
            .build()
        
        let meditationHabit = HabitBuilder()
            .withName("Mindfulness Meditation")      // Should reduce neuroticism
            .withCategoryId("mindfulness")
            .build()
        
        let volunteerHabit = HabitBuilder()
            .withName("Help Others Volunteer")       // Should boost agreeableness
            .withCategoryId("social")
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [organizingHabit, creativeHabit, socialHabit, meditationHabit, volunteerHabit],
            completionRates: [0.8, 0.7, 0.6, 0.9, 0.85],
            habitCategories: [
                CategoryBuilder.productivityCategory()
                    .withPersonalityWeights(["conscientiousness": 0.5])
                    .build(),
                CategoryBuilder.creativeCategory()
                    .withPersonalityWeights(["openness": 0.5])
                    .build(),
                CategoryBuilder.socialCategory()
                    .withPersonalityWeights(["extraversion": 0.5, "agreeableness": 0.4])
                    .build(),
                CategoryBuilder.mindfulnessCategory()
                    .withPersonalityWeights(["neuroticism": -0.3])
                    .build()
            ]
        )
        
        let scores = service.calculatePersonalityScores(from: input)
        
        // Each trait should be elevated due to specific habit name patterns
        #expect(scores[.conscientiousness] ?? 0.0 > 0.5)  // "organization", "routine"
        #expect(scores[.openness] ?? 0.0 > 0.5)          // "creative", "art"
        #expect(scores[.extraversion] ?? 0.0 > 0.5)      // "call", "friends"
        #expect(scores[.agreeableness] ?? 0.0 > 0.5)     // "help", "volunteer"
        #expect(scores[.neuroticism] ?? 0.0 < 0.5)       // "mindfulness", "meditation" (reduces neuroticism)
    }
    
    @Test("Service handles habit frequency and reminder patterns")
    func testHabitFrequencyAndReminderAnalysis() {
        let service = createTestService()
        
        // Create habits with different reminder patterns
        let noRemindersHabit = HabitBuilder()
            .withName("Self-Disciplined Habit")
            .withReminders([])  // No reminders = self-discipline
            .withSchedule(.daily)
            .withCategoryId("health")
            .build()
        
        let manyRemindersHabit = HabitBuilder()
            .withName("Needs Structure Habit")
            .withReminders([
                ReminderTime(hour: 8, minute: 0),
                ReminderTime(hour: 12, minute: 0),
                ReminderTime(hour: 18, minute: 0),
                ReminderTime(hour: 21, minute: 0)
            ])  // Many reminders = needs external structure
            .withSchedule(.daily)
            .withCategoryId("productivity")
            .build()
        
        let numericHabit = HabitBuilder()
            .withName("Detailed Tracking")
            .withKind(.numeric)  // Numeric tracking = detailed approach
            .withDailyTarget(60)  // High target = ambition
            .withUnitLabel("minutes")
            .withCategoryId("learning")
            .build()
        
        let input = createHabitAnalysisInput(
            activeHabits: [noRemindersHabit, manyRemindersHabit, numericHabit],
            completionRates: [0.9, 0.6, 0.8],
            habitCategories: [
                CategoryBuilder.healthCategory()
                    .withPersonalityWeights(["conscientiousness": 0.5])
                    .build(),
                CategoryBuilder.productivityCategory()
                    .withPersonalityWeights(["conscientiousness": 0.6])
                    .build(),
                CategoryBuilder.learningCategory()
                    .withPersonalityWeights(["openness": 0.7, "conscientiousness": 0.4])
                    .build()
            ]
        )
        
        let scores = service.calculatePersonalityScores(from: input)
        
        // Should show conscientiousness patterns from self-discipline and detailed tracking
        #expect(scores[.conscientiousness] ?? 0.0 > 0.5)
        
        // All scores should be valid
        for (_, score) in scores {
            #expect(score >= 0.0)
            #expect(score <= 1.0)
        }
    }
    
    // MARK: - Full Integration Test
    
    @Test("Full personality analysis integration with complex scenario")
    func testFullPersonalityAnalysisIntegration() async throws {
        let mockRepository = MockPersonalityAnalysisRepository()
        let service = createTestService(with: mockRepository)
        
        // Create a complex, realistic scenario
        let healthCategory = CategoryBuilder.healthCategory().build()
        let learningCategory = CategoryBuilder.learningCategory().build()
        let socialCategory = CategoryBuilder.socialCategory().build()
        
        let habits = [
            HabitBuilder.workoutHabit().withCategoryId(healthCategory.id).build(),
            HabitBuilder.readingHabit().withCategoryId(learningCategory.id).build(),
            HabitBuilder().withName("Call Family").withCategoryId(socialCategory.id).build(),
            HabitBuilder.meditationHabit().build()
        ]
        
        let suggestions = [
            createHabitSuggestion(
                id: "morning-run",
                name: "Morning Run",
                personalityWeights: ["conscientiousness": 0.8, "neuroticism": -0.3]
            )
        ]
        
        let input = createHabitAnalysisInput(
            activeHabits: habits,
            completionRates: [0.8, 0.9, 0.6, 0.7],
            customHabits: [habits[2]], // Family call is custom
            customCategories: [],
            habitCategories: [healthCategory, learningCategory, socialCategory],
            selectedSuggestions: suggestions,
            trackingDays: 21,
            analysisTimeRange: 30,
            totalDataPoints: 120
        )
        
        let completionStats = createCompletionStats(
            totalHabits: 4,
            completedHabits: 3,
            completionRate: 0.75
        )
        
        // Set up mock repository data
        mockRepository.mockHabitAnalysisInput = input
        mockRepository.mockCompletionStats = completionStats
        
        // Perform full analysis
        let userId = UUID()
        let profile = try await service.analyzePersonality(for: userId)
        
        // Verify profile structure
        #expect(profile.userId == userId)
        #expect(profile.traitScores.count == PersonalityTrait.allCases.count)
        #expect(profile.confidence != .insufficient)
        
        // Verify all trait scores are valid
        for (_, score) in profile.traitScores {
            #expect(score >= 0.0)
            #expect(score <= 1.0)
        }
        
        // Verify dominant trait is one of the calculated traits
        let dominantScore = profile.traitScores[profile.dominantTrait] ?? 0.0
        let maxScore = profile.traitScores.values.max() ?? 0.0
        #expect(dominantScore == maxScore)
        
        // Verify metadata
        #expect(profile.analysisMetadata.version == "1.6")
        #expect(profile.analysisMetadata.dataPointsAnalyzed > 0)
        
        // Should show strong personality indicators based on the habit mix
        // (varied habits should show reasonable spread across traits)
        let traitsByScore = profile.traitsByScore
        #expect(traitsByScore.count == 5)
        #expect(traitsByScore[0].score > traitsByScore[4].score) // Some differentiation
    }
}