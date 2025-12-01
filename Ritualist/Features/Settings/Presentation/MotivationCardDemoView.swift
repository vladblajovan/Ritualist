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
    @State private var dismissedTriggers: [String] = []
    @State private var lastResetDate: Date?
    @State private var showingDocumentation = false

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
        DemoScenario(title: "Comeback Story", trigger: .comebackStory, completion: 0.60, timeOfDay: .evening),
        DemoScenario(title: "Empty Day - No Habits Scheduled", trigger: .emptyDay, completion: 0.0, timeOfDay: .morning)
    ]

    // Demo items for carousel
    private var carouselDemoItems: [InspirationItem] {
        [
            InspirationItem(
                trigger: .strongFinish,
                message: "75%+ achieved. Excellence within reach!",
                slogan: "Excellence becomes your standard."
            ),
            InspirationItem(
                trigger: .halfwayPoint,
                message: "Halfway there! Keep the momentum going!",
                slogan: "Midday momentum, unstoppable force."
            ),
            InspirationItem(
                trigger: .afternoonPush,
                message: "Final push time! You're almost there.",
                slogan: "Finish strong, tomorrow starts now."
            )
        ].compactMap { $0 }
    }

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

                    // Reset Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Dismissed Triggers Data")
                                .font(.headline)
                            Spacer()
                            Button("Reset All") {
                                clearDismissedTriggers()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }

                        if let resetDate = lastResetDate {
                            Text("Last Reset: \(resetDate, style: .date) at \(resetDate, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Last Reset: Never")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if dismissedTriggers.isEmpty {
                            Text("No triggers dismissed today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dismissed Today (\(dismissedTriggers.count)):")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                ForEach(dismissedTriggers, id: \.self) { trigger in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text(trigger)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    // Carousel Demo Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Carousel Demo")
                                .font(.headline)
                            Spacer()
                            Text("Swipe to navigate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        InspirationCarouselView(
                            items: carouselDemoItems,
                            timeOfDay: .noon,
                            completionPercentage: 0.65,
                            onDismiss: { _ in },
                            onDismissAll: {}
                        )
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    // Single Card Demos
                    Text("Individual Card Variants")
                        .font(.headline)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingDocumentation = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDocumentation) {
                MotivationTriggersDocumentationView()
            }
            .onAppear {
                loadDismissedTriggers()
            }
        }
    }

    // MARK: - Data Management

    /// Load dismissed triggers from UserDefaults
    private func loadDismissedTriggers() {
        // Load dismissed triggers array
        if let dismissedData = UserDefaults.standard.data(forKey: UserDefaultsKeys.dismissedTriggersToday),
           let dismissedArray = try? JSONDecoder().decode([String].self, from: dismissedData) {
            dismissedTriggers = dismissedArray
        } else {
            dismissedTriggers = []
        }

        // Load last reset date
        lastResetDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastInspirationResetDate) as? Date
    }

    /// Clear all dismissed triggers and reset data
    private func clearDismissedTriggers() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.dismissedTriggersToday)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastInspirationResetDate)
        dismissedTriggers = []
        lastResetDate = nil
    }

    // MARK: - Helper Methods

    /// Generate representative message for each trigger type
    private func generateMessage(for trigger: InspirationTrigger) -> String {
        switch trigger {
        case .sessionStart:
            return "Time to execute your daily plan with precision."
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
            return "Perfect day achieved! You've shown incredible dedication!"
        case .eveningReflection:
            return "Great day! You completed 70% of your habits."
        case .weekendMotivation:
            return "Weekend habits count too. Keep the momentum going!"
        case .comebackStory:
            return "Today's better than yesterday. That's real progress!"
        case .emptyDay:
            return "No habits scheduled today. A perfect time to plan ahead."
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
        case .emptyDay:
            return "Rest and reflection build momentum."
        }
    }
}

// MARK: - Documentation View

struct MotivationTriggersDocumentationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Introduction
                    Section {
                        Text("Motivational messages appear automatically based on your progress and time of day. The system intelligently selects the most relevant message to keep you motivated throughout your habit journey.")
                            .font(.body)
                    }

                    // Trigger Types
                    Section {
                        Text("Trigger Types")
                            .font(.title2)
                            .fontWeight(.bold)

                        TriggerRow(
                            name: "Perfect Day",
                            condition: "100% completion",
                            priority: "Highest",
                            cooldown: "None",
                            color: .green
                        )

                        TriggerRow(
                            name: "Empty Day",
                            condition: "No habits scheduled today",
                            priority: "Very High",
                            cooldown: "None",
                            color: .teal
                        )

                        TriggerRow(
                            name: "Strong Finish",
                            condition: "75%+ completion",
                            priority: "Very High",
                            cooldown: "60 minutes",
                            color: .blue
                        )

                        TriggerRow(
                            name: "Comeback Story",
                            condition: "25%+ improvement from yesterday",
                            priority: "High",
                            cooldown: "3 hours",
                            color: .purple
                        )

                        TriggerRow(
                            name: "First Habit Complete",
                            condition: "First habit of the day completed",
                            priority: "High",
                            cooldown: "60 minutes",
                            color: .orange
                        )

                        TriggerRow(
                            name: "Halfway Point",
                            condition: "50%+ completion",
                            priority: "Medium",
                            cooldown: "60 minutes",
                            color: .orange
                        )

                        TriggerRow(
                            name: "Afternoon Push",
                            condition: "3-5 PM with <60% completion",
                            priority: "Medium",
                            cooldown: "2 hours",
                            color: .indigo
                        )

                        TriggerRow(
                            name: "Struggling Mid-Day",
                            condition: "Noon with <40% completion",
                            priority: "Medium",
                            cooldown: "2 hours",
                            color: .indigo
                        )

                        TriggerRow(
                            name: "Morning Motivation",
                            condition: "Morning with 0% completion",
                            priority: "Low",
                            cooldown: "2 hours",
                            color: .pink
                        )

                        TriggerRow(
                            name: "Evening Reflection",
                            condition: "Evening with 60%+ completion",
                            priority: "Low",
                            cooldown: "3 hours",
                            color: .purple
                        )

                        TriggerRow(
                            name: "Weekend Motivation",
                            condition: "Weekend morning",
                            priority: "Low",
                            cooldown: "3 hours",
                            color: .cyan
                        )

                        TriggerRow(
                            name: "Session Start",
                            condition: "First app open of the day",
                            priority: "Lowest",
                            cooldown: "None",
                            color: .gray
                        )
                    }

                    // Dismissal Behavior
                    Section {
                        Text("Dismissal Behavior")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                title: "Acknowledging Messages",
                                description: "Tapping the checkmark acknowledges the message and marks it as seen."
                            )

                            InfoRow(
                                icon: "clock.fill",
                                iconColor: .blue,
                                title: "Cooldown Period",
                                description: "Each dismissed trigger has a cooldown period (60 minutes to 3 hours) before it can appear again."
                            )

                            InfoRow(
                                icon: "calendar.circle.fill",
                                iconColor: .orange,
                                title: "Daily Reset",
                                description: "All dismissed triggers reset at midnight. You'll see fresh motivational messages each day."
                            )

                            InfoRow(
                                icon: "star.fill",
                                iconColor: .yellow,
                                title: "Priority System",
                                description: "Higher priority triggers (Perfect Day, Strong Finish) override lower priority ones when multiple conditions are met."
                            )

                            InfoRow(
                                icon: "brain.fill",
                                iconColor: .purple,
                                title: "Personalization",
                                description: "Messages are personalized based on your Big Five personality profile, adapting to your motivational style."
                            )
                        }
                    }

                    // Smart Behavior
                    Section {
                        Text("Smart Behavior")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("The system prevents message fatigue by:")
                            .font(.body)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Only showing one message at a time")
                            BulletPoint(text: "Respecting cooldown periods between triggers")
                            BulletPoint(text: "Filtering out already dismissed messages")
                            BulletPoint(text: "Only showing messages when viewing today (not past dates)")
                            BulletPoint(text: "Prioritizing celebration messages over routine encouragement")
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Motivation System")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TriggerRow: View {
    let name: String
    let condition: String
    let priority: String
    let cooldown: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Condition:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(condition)
                        .font(.caption)
                }

                HStack {
                    Text("Priority:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(priority)
                        .font(.caption)

                    Spacer()

                    Text("Cooldown:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cooldown)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    MotivationCardDemoView()
}
#endif
