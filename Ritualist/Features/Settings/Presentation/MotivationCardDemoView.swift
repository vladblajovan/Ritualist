//
//  MotivationCardDemoView.swift
//  Ritualist
//
//  Created by Claude for UX testing and development
//

import SwiftUI
import RitualistCore

#if DEBUG
struct MotivationCardDemoView: View {
    @Environment(\.dismiss) private var dismiss

    // Demo scenario configuration
    private struct DemoScenario {
        let title: String
        let trigger: InspirationTrigger
        let completion: Double
        let timeOfDay: TimeOfDay
    }

    // Demo configurations for different scenarios
    private let demoScenarios: [DemoScenario] = [
        DemoScenario(title: "Perfect Day - 100% Complete (Green)", trigger: .perfectDay, completion: 1.0, timeOfDay: .evening),
        DemoScenario(title: "Strong Finish - 75%+ (Blue)", trigger: .strongFinish, completion: 0.75, timeOfDay: .noon),
        DemoScenario(title: "Halfway Point - 50% (Orange)", trigger: .halfwayPoint, completion: 0.5, timeOfDay: .noon),
        DemoScenario(title: "Session Start - Morning", trigger: .sessionStart, completion: 0.0, timeOfDay: .morning),
        DemoScenario(title: "Morning Motivation", trigger: .morningMotivation, completion: 0.0, timeOfDay: .morning),
        DemoScenario(title: "First Habit Complete", trigger: .firstHabitComplete, completion: 0.2, timeOfDay: .morning),
        DemoScenario(title: "Struggling Mid-Day", trigger: .strugglingMidDay, completion: 0.35, timeOfDay: .noon),
        DemoScenario(title: "Afternoon Push", trigger: .afternoonPush, completion: 0.55, timeOfDay: .noon),
        DemoScenario(title: "Evening Reflection", trigger: .eveningReflection, completion: 0.70, timeOfDay: .evening),
        DemoScenario(title: "Weekend Motivation", trigger: .weekendMotivation, completion: 0.45, timeOfDay: .noon),
        DemoScenario(title: "Comeback Story", trigger: .comebackStory, completion: 0.60, timeOfDay: .evening)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Motivational Card Variants")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("All trigger types and completion states for visual testing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Demo cards
                    ForEach(Array(demoScenarios.enumerated()), id: \.offset) { index, scenario in
                        VStack(alignment: .leading, spacing: 12) {
                            // Scenario label
                            HStack {
                                Text(scenario.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("\(Int(scenario.completion * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)

                            // The actual card
                            InspirationCard(
                                message: generateMessage(for: scenario.trigger),
                                slogan: generateSlogan(for: scenario.trigger),
                                timeOfDay: scenario.timeOfDay,
                                completionPercentage: scenario.completion,
                                shouldShow: true,
                                onDismiss: {}
                            )
                            .padding(.horizontal, 20)
                        }
                    }

                    // Footer info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Testing Notes")
                            .font(.headline)

                        Text("• Dismiss buttons are non-functional in demo mode")
                        Text("• Messages shown are representative samples")
                        Text("• Actual messages vary based on personality profile")
                        Text("• Cards auto-adapt gradient and icons based on completion")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Motivation Cards Demo")
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

    // MARK: - Helper Methods

    /// Generate representative message for each trigger type
    private func generateMessage(for trigger: InspirationTrigger) -> String {
        switch trigger {
        case .sessionStart:
            return "Time to execute your daily plan with precision. 🎯"
        case .morningMotivation:
            return "Good morning! Ready to make today incredible?"
        case .firstHabitComplete:
            return "Yes! First win of the day. Momentum is building!"
        case .halfwayPoint:
            return "Halfway there! Your consistency is paying off."
        case .strugglingMidDay:
            return "One step at a time. You've got this."
        case .afternoonPush:
            return "Final push time! You're almost there."
        case .strongFinish:
            return "Incredible progress! 75% complete and climbing!"
        case .perfectDay:
            return "🎊 Perfect day achieved! You've shown incredible dedication!"
        case .eveningReflection:
            return "Great day! You completed 70% of your habits."
        case .weekendMotivation:
            return "Weekend habits count too. Keep the momentum going!"
        case .comebackStory:
            return "Today's better than yesterday. That's real progress!"
        }
    }

    /// Generate slogan for each trigger type
    private func generateSlogan(for trigger: InspirationTrigger) -> String {
        switch trigger {
        case .sessionStart:
            return "Your morning sets the entire tone."
        case .morningMotivation:
            return "Rise with purpose, rule your day."
        case .firstHabitComplete:
            return "First step creates unstoppable momentum."
        case .halfwayPoint:
            return "Midday momentum, unstoppable force."
        case .strugglingMidDay:
            return "Progress happens one habit at a time."
        case .afternoonPush:
            return "Finish strong, tomorrow starts now."
        case .strongFinish:
            return "Excellence becomes your standard."
        case .perfectDay:
            return "Consistency creates extraordinary results."
        case .eveningReflection:
            return "End strong, dream bigger."
        case .weekendMotivation:
            return "Weekend winners become champions."
        case .comebackStory:
            return "Every improvement counts forward."
        }
    }
}

#Preview {
    MotivationCardDemoView()
}
#endif
