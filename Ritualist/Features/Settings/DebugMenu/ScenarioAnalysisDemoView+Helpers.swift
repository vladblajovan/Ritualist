//
//  ScenarioAnalysisDemoView+Helpers.swift
//  Ritualist
//
//  Helper methods for building test data and running personality analysis demos.
//

import SwiftUI
import RitualistCore

#if DEBUG

// MARK: - Intermediate Types for Analysis Building

extension ScenarioAnalysisDemoView {

    /// Intermediate result from building suggested habits
    struct SuggestedHabitsResult {
        let habits: [Habit]
        let suggestions: [HabitSuggestion]
    }

    /// Intermediate result from building custom data
    struct CustomDataResult {
        let categories: [HabitCategory]
        let habits: [Habit]
    }

    /// Combined data ready for analysis
    struct AnalysisInputData {
        let allHabits: [Habit]
        let allCategories: [HabitCategory]
        let selectedSuggestions: [HabitSuggestion]
        let customHabits: [Habit]
        let customCategories: [HabitCategory]
        let avgCompletionRate: Double
        let completionRates: [Double]
    }

    /// Input parameters for building analysis result
    struct AnalysisResultInput {
        let dominantTrait: PersonalityTrait
        let scores: [PersonalityTrait: Double]
        let suggestedHabits: [Habit]
        let customHabits: [Habit]
        let usedCategories: [HabitCategory]
        let customCategories: [HabitCategory]
        let avgCompletionRate: Double
    }
}

// MARK: - Habit Building Helpers

extension ScenarioAnalysisDemoView {

    /// Builds suggested habits from preferred predefined categories
    func buildSuggestedHabits(
        config: TestDataScenarioConfig,
        preferredCategoryIds: [String],
        predefinedCategories: [HabitCategory]
    ) -> SuggestedHabitsResult {
        var suggestedHabits: [Habit] = []
        var selectedSuggestions: [HabitSuggestion] = []
        var habitIndex = 0

        for categoryId in preferredCategoryIds {
            let habitsPerCategory = config.suggestedHabitCount / preferredCategoryIds.count + 1
        let habitsForCategory = getSuggestedHabitsForCategory(categoryId, count: habitsPerCategory)

            for (name, emoji) in habitsForCategory {
                if suggestedHabits.count >= config.suggestedHabitCount {
                    break
                }

                let suggestionId = "demo_\(categoryId)_\(habitIndex)"

                let habit = Habit(
                    id: UUID(),
                    name: name,
                    colorHex: "#3498DB",
                    emoji: emoji,
                    kind: .binary,
                    schedule: .daily,
                    displayOrder: habitIndex,
                    categoryId: categoryId,
                    suggestionId: suggestionId
                )
                suggestedHabits.append(habit)

                // Create matching HabitSuggestion with weights from predefined category
                let categoryWeights = predefinedCategories
                    .first { $0.id == categoryId }?
                    .personalityWeights

                let suggestion = HabitSuggestion(
                    id: suggestionId,
                    name: name,
                    emoji: emoji,
                    colorHex: "#3498DB",
                    categoryId: categoryId,
                    kind: .binary,
                    description: "Demo habit for testing",
                    personalityWeights: categoryWeights
                )
                selectedSuggestions.append(suggestion)

                habitIndex += 1
            }
        }

        return SuggestedHabitsResult(habits: suggestedHabits, suggestions: selectedSuggestions)
    }

    /// Builds custom categories and habits from scenario-specific test data
    func buildCustomData(
        config: TestDataScenarioConfig,
        startingHabitIndex: Int
    ) -> CustomDataResult {
        let customCategoryData = testDataService.getPersonalityCategories(for: scenario)
        let customHabitData = testDataService.getPersonalityHabits(for: scenario)

        // Build custom categories
        let customCategories: [HabitCategory] = customCategoryData
            .prefix(config.customCategoryCount)
            .enumerated()
            .map { index, data in
                HabitCategory(
                    id: data.name,
                    name: data.name,
                    displayName: data.displayName,
                    emoji: data.emoji,
                    order: 100 + index,
                    isPredefined: false,
                    personalityWeights: nil
                )
            }

        // Build custom habits
        var customHabits: [Habit] = []
        for (index, data) in customHabitData.prefix(config.customHabitCount).enumerated() {
            let categoryId = customCategories.isEmpty ? nil : customCategories[index % customCategories.count].id

            let habit = Habit(
                id: UUID(),
                name: data.name,
                colorHex: data.colorHex,
                emoji: data.emoji,
                kind: data.kind,
                unitLabel: data.unitLabel,
                dailyTarget: data.dailyTarget,
                schedule: data.schedule,
                displayOrder: startingHabitIndex + index,
                categoryId: categoryId
            )
            customHabits.append(habit)
        }

        return CustomDataResult(categories: customCategories, habits: customHabits)
    }
}

// MARK: - Analysis Building Helpers

extension ScenarioAnalysisDemoView {

    /// Combines suggested and custom data into a complete analysis input
    func buildAnalysisInputData(
        suggestedResult: SuggestedHabitsResult,
        customResult: CustomDataResult,
        predefinedCategories: [HabitCategory],
        config: TestDataScenarioConfig
    ) -> AnalysisInputData {
        let allHabits = suggestedResult.habits + customResult.habits

        // Filter predefined categories to only those used
        let usedPredefinedCategories = predefinedCategories.filter { category in
            allHabits.contains { $0.categoryId == category.id }
        }
        let allCategories = usedPredefinedCategories + customResult.categories

        // Generate completion rates based on scenario config
        let avgCompletionRate = (config.completionRateRange.lowerBound + config.completionRateRange.upperBound) / 2
        let completionRates = allHabits.map { _ in
            Double.random(in: config.completionRateRange)
        }

        return AnalysisInputData(
            allHabits: allHabits,
            allCategories: allCategories,
            selectedSuggestions: suggestedResult.suggestions,
            customHabits: customResult.habits,
            customCategories: customResult.categories,
            avgCompletionRate: avgCompletionRate,
            completionRates: completionRates
        )
    }

    /// Creates the HabitAnalysisInput for the personality service
    func createHabitAnalysisInput(from data: AnalysisInputData, config: TestDataScenarioConfig) -> HabitAnalysisInput {
        HabitAnalysisInput(
            activeHabits: data.allHabits,
            completionRates: data.completionRates,
            customHabits: data.customHabits,
            customCategories: data.customCategories,
            habitCategories: data.allCategories,
            selectedSuggestions: data.selectedSuggestions,
            trackingDays: config.historyDays,
            analysisTimeRange: config.historyDays,
            totalDataPoints: data.allHabits.count * config.historyDays
        )
    }

    /// Creates completion stats for the analysis
    func createCompletionStats(from data: AnalysisInputData) -> HabitCompletionStats {
        let completedCount = Int(Double(data.allHabits.count) * data.avgCompletionRate)

        return HabitCompletionStats(
            totalHabits: data.allHabits.count,
            completedHabits: completedCount,
            completionRate: data.avgCompletionRate
        )
    }

    /// Builds the final AnalysisResult from personality scores and input data
    func buildAnalysisResult(from input: AnalysisResultInput) -> AnalysisResult {
        let suggestedNames = input.suggestedHabits.map { $0.name }
        let customNames = input.customHabits.map { $0.name }
        let categoryNames = input.usedCategories.map { $0.displayName } + input.customCategories.map { $0.displayName }

        return AnalysisResult(
            dominantTrait: input.dominantTrait,
            traitScores: input.scores,
            habits: suggestedNames + customNames,
            categories: categoryNames,
            completionRate: input.avgCompletionRate
        )
    }
}

#endif
