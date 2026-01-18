//
//  TestDataScenariosView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.11.2025.
//

import SwiftUI
import RitualistCore
import NaturalLanguage
import FactoryKit

#if DEBUG
struct TestDataScenariosView: View {
    @Bindable var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("Choose a test data scenario to populate the database. Each scenario represents a different user journey stage with specific data characteristics.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Available Scenarios")
            }

            // Scenario Cards
            ForEach(TestDataScenario.allCases) { scenario in
                Section {
                    Button {
                        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                        Task { @MainActor in
                            await vm.populateTestData(scenario: scenario)
                        }
                    } label: {
                        ScenarioCardView(
                            scenario: scenario,
                            isPopulating: vm.isPopulatingTestData
                        )
                    }
                    .disabled(vm.isPopulatingTestData || vm.isClearingDatabase)
                    .buttonStyle(.plain)
                }
            }

            // Progress Bar (shown when populating)
            if vm.isPopulatingTestData {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "hourglass")
                                .foregroundColor(.blue)

                            Text(vm.testDataProgressMessage.isEmpty ? "Populating test data..." : vm.testDataProgressMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        ProgressView(value: vm.testDataProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                    .padding(.vertical, 4)
                }
            }

            // ML Analysis Demo
            Section {
                Text("Compare keyword-based vs ML-based personality analysis for each scenario's custom habits and categories.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                MLAnalysisDemoView()
            } header: {
                HStack {
                    Text("ML Analysis Demo")
                    Spacer()
                    if #available(iOS 17.0, *), NLEmbedding.wordEmbedding(for: .english) != nil {
                        Text("ML Available")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("Keyword Only")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .navigationTitle("Test Data Scenarios")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Scenario Card View

struct ScenarioCardView: View {
    let scenario: TestDataScenario
    let isPopulating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and name
            HStack(spacing: 12) {
                Text(scenario.icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(scenario.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Detailed description
            Text(scenario.detailedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Key metrics
            let config = TestDataScenarioConfig.config(for: scenario)
            let availability = ScenarioFeatureAvailability.availability(for: scenario)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("\(config.totalHabitCount) habits", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    Label("\(config.historyDays) days", systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }

                HStack {
                    Label(availability.dashboardMetricsLevel, systemImage: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundColor(.green)

                    if availability.personalityAnalysisAvailable {
                        Label("Personality: \(availability.personalityAnalysisConfidence)", systemImage: "brain.head.profile")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        Label("Personality: N/A", systemImage: "xmark.circle")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(isPopulating ? 0.5 : 1.0)
    }
}

// MARK: - ML Analysis Demo View

struct MLAnalysisDemoView: View {
    @State private var selectedScenario: TestDataScenario = .opennessProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Scenario selector - show all scenarios for comparison
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(TestDataScenario.allCases) { scenario in
                    Text("\(scenario.icon) \(scenario.rawValue)").tag(scenario)
                }
            }
            .pickerStyle(.menu)

            // Show analysis for selected scenario
            ScenarioAnalysisDemoView(scenario: selectedScenario)
        }
        .padding(.vertical, 8)
    }
}

struct ScenarioAnalysisDemoView: View {
    let scenario: TestDataScenario
    @Injected(\.personalityAnalysisService) var personalityService
    @Injected(\.testDataPopulationService) var testDataService

    @State private var mlAvailable: Bool = false
    @State private var analysisResult: AnalysisResult?

    /// Result of running personality analysis on scenario data
    struct AnalysisResult {
        let dominantTrait: PersonalityTrait
        let traitScores: [PersonalityTrait: Double]
        let habits: [String]
        let categories: [String]
        let completionRate: Double
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(scenario.icon) \(scenario.rawValue)")
                .font(.headline)

            if let result = analysisResult {
                // Show actual habits from test data service
                Text("Habits (\(result.habits.count)):")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(result.habits.prefix(4), id: \.self) { habit in
                    Text("• \(habit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if result.habits.count > 4 {
                    Text("  + \(result.habits.count - 4) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }

                Text("Categories: \(result.categories.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Avg Completion: \(Int(result.completionRate * 100))%")
                    .font(.caption)
                    .foregroundColor(result.completionRate > 0.5 ? .green : .orange)

                Divider()

                // Show computed analysis result
                VStack(alignment: .leading, spacing: 8) {
                    Text("Computed Dominant Trait:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack {
                        Text(result.dominantTrait.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(traitColor(result.dominantTrait).opacity(0.2))
                            .foregroundColor(traitColor(result.dominantTrait))
                            .cornerRadius(4)

                        Text("(\(Int((result.traitScores[result.dominantTrait] ?? 0) * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    // Show all trait scores
                    Text("All Trait Scores:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.top, 4)

                    ForEach(result.traitScores.sorted(by: { $0.value > $1.value }), id: \.key) { trait, score in
                        HStack {
                            Text(trait.displayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 120, alignment: .leading)

                            ProgressView(value: score, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: traitColor(trait)))
                                .frame(maxWidth: .infinity)

                            Text("\(Int(score * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
            } else {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Running analysis...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            Divider()

            // ML availability info
            HStack {
                Text("Analysis Method:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if mlAvailable {
                    Text("ML + Keyword")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Keyword Only")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            checkMLAvailability()
            runAnalysis()
        }
        .onChange(of: scenario) { _, _ in
            runAnalysis()
        }
    }

    private func traitColor(_ trait: PersonalityTrait) -> Color {
        switch trait {
        case .openness: return .purple
        case .conscientiousness: return .blue
        case .extraversion: return .yellow
        case .agreeableness: return .pink
        case .neuroticism: return .red
        }
    }

    func runAnalysis() {
        let config = TestDataScenarioConfig.config(for: scenario)
        let predefinedCategories = getPredefinedCategoriesForDemo()
        let preferredCategoryIds = getPreferredCategoryIds(for: scenario)

        // Build suggested habits from predefined categories
        let suggestedResult = buildSuggestedHabits(
            config: config,
            preferredCategoryIds: preferredCategoryIds,
            predefinedCategories: predefinedCategories
        )

        // Build custom categories and habits
        let customResult = buildCustomData(
            config: config,
            startingHabitIndex: suggestedResult.habits.count
        )

        // Combine into analysis input data
        let inputData = buildAnalysisInputData(
            suggestedResult: suggestedResult,
            customResult: customResult,
            predefinedCategories: predefinedCategories,
            config: config
        )

        // Create analysis input and completion stats
        let input = createHabitAnalysisInput(from: inputData, config: config)
        let completionStats = createCompletionStats(from: inputData)

        // Run personality analysis
        let (scores, _, _) = personalityService.calculatePersonalityScoresWithDetails(
            from: input,
            completionStats: completionStats
        )
        let dominantTrait = personalityService.determineDominantTrait(from: scores)

        // Filter to used predefined categories for display
        let usedPredefinedCategories = predefinedCategories.filter { category in
            inputData.allHabits.contains { $0.categoryId == category.id }
        }

        // Build final result
        analysisResult = buildAnalysisResult(
            dominantTrait: dominantTrait,
            scores: scores,
            suggestedHabits: suggestedResult.habits,
            customHabits: customResult.habits,
            usedCategories: usedPredefinedCategories,
            customCategories: customResult.categories,
            avgCompletionRate: inputData.avgCompletionRate
        )
    }

    /// Returns predefined categories with their personality weights (matching CategoryDefinitionsService)
    private func getPredefinedCategoriesForDemo() -> [HabitCategory] {
        [
            HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "💪", order: 0, isPredefined: true,
                         personalityWeights: ["conscientiousness": 0.6, "neuroticism": -0.3, "agreeableness": 0.2]),
            HabitCategory(id: "wellness", name: "wellness", displayName: "Wellness", emoji: "🧘", order: 1, isPredefined: true,
                         personalityWeights: ["conscientiousness": 0.4, "neuroticism": -0.5, "openness": 0.3, "agreeableness": 0.2]),
            HabitCategory(id: "productivity", name: "productivity", displayName: "Productivity", emoji: "⚡", order: 2, isPredefined: true,
                         personalityWeights: ["conscientiousness": 0.8, "neuroticism": -0.2, "openness": 0.1]),
            HabitCategory(id: "social", name: "social", displayName: "Social", emoji: "👥", order: 3, isPredefined: true,
                         personalityWeights: ["extraversion": 0.7, "agreeableness": 0.6, "conscientiousness": 0.3, "neuroticism": -0.3]),
            HabitCategory(id: "learning", name: "learning", displayName: "Learning", emoji: "📚", order: 4, isPredefined: true,
                         personalityWeights: ["openness": 0.8, "conscientiousness": 0.5, "extraversion": 0.2, "neuroticism": -0.2]),
            HabitCategory(id: "creativity", name: "creativity", displayName: "Creativity", emoji: "🎨", order: 5, isPredefined: true,
                         personalityWeights: ["openness": 0.9, "extraversion": 0.3, "conscientiousness": 0.1, "neuroticism": -0.3])
        ]
    }

    /// Returns preferred predefined category IDs for each personality profile
    private func getPreferredCategoryIds(for scenario: TestDataScenario) -> [String] {
        switch scenario {
        case .opennessProfile: return ["learning", "creativity"]
        case .conscientiousnessProfile: return ["productivity", "health"]
        case .extraversionProfile: return ["social"]
        case .agreeablenessProfile: return ["social"]
        case .neuroticismProfile: return ["health", "wellness"]
        default: return ["health", "wellness", "productivity", "social", "learning", "creativity"]
        }
    }

    /// Returns sample habit names for a predefined category
    func getSuggestedHabitsForCategory(_ categoryId: String, count: Int) -> [(name: String, emoji: String)] {
        let allHabits: [String: [(String, String)]] = [
            "health": [("Drink Water", "💧"), ("Exercise", "🏋️‍♂️"), ("Walk", "🚶‍♀️"), ("Eat Fruits", "🍎"), ("Stretch", "🤸‍♀️"), ("Take Vitamins", "💊")],
            "wellness": [("Meditate", "🧘‍♀️"), ("Sleep Early", "😴"), ("Deep Breathing", "🫁"), ("Gratitude Journal", "📝"), ("Nature Time", "🌲"), ("Digital Detox", "📱")],
            "productivity": [("Plan Your Day", "📋"), ("Clean Workspace", "🧹"), ("Make Bed", "🛏️"), ("Time Blocking", "⏰"), ("Clear Email", "📧"), ("Review Goals", "🎯")],
            "social": [("Call Family", "📞"), ("Give Compliment", "😊"), ("Help Someone", "🤝"), ("Text Friends", "💬"), ("Volunteer", "❤️"), ("Thank Someone", "🙏")],
            "learning": [("Read", "📚"), ("Language Practice", "🗣️"), ("Learn New Skill", "🎯"), ("Watch Documentary", "🎬"), ("Practice Instrument", "🎸"), ("Listen Podcast", "🎧")],
            "creativity": [("Creative Writing", "✍️"), ("Sketch & Draw", "✏️"), ("Photography", "📸"), ("Brainstorm Ideas", "💡"), ("Creative Cooking", "👨‍🍳"), ("Design", "🎨")]
        ]
        return Array((allHabits[categoryId] ?? []).prefix(count))
    }

    private func checkMLAvailability() {
        if #available(iOS 17.0, *) {
            mlAvailable = NLEmbedding.wordEmbedding(for: .english) != nil
        } else {
            mlAvailable = false
        }
    }
}

#endif
