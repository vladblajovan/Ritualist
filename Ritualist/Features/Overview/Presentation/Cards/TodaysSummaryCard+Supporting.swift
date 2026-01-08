//
//  TodaysSummaryCard+Supporting.swift
//  Ritualist
//
//  Supporting views and modifiers for TodaysSummaryCard
//

import SwiftUI
import RitualistCore

// MARK: - Schedule Icon Info Sheet

struct ScheduleIconInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScheduleInfoRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Time-Based Reminders",
                        description: "Habit has scheduled notification reminders at specific times"
                    )

                    ScheduleInfoRow(
                        icon: "location.fill",
                        iconColor: .purple,
                        title: "Location-Based Reminders",
                        description: "Habit has geofence reminders that trigger when arriving or leaving a location"
                    )
                } header: {
                    Text("Reminder Icons")
                } footer: {
                    Text("These icons show which reminder features are enabled for each habit (Pro feature).")
                }

                Section {
                    ScheduleInfoRow(
                        icon: "infinity.circle.fill",
                        iconColor: .blue,
                        title: "Always Available",
                        description: "Daily habits that can be logged any day"
                    )

                    ScheduleInfoRow(
                        icon: "calendar.circle.fill",
                        iconColor: .green,
                        title: "Scheduled for Today",
                        description: "Habit is scheduled for specific days, and today is one of them"
                    )
                } header: {
                    Text("Schedule Icons")
                } footer: {
                    Text("These icons indicate when habits are available to log based on their schedule type.")
                }

                Section {
                    StreakInfoRow()
                } header: {
                    Text("Streak Indicator")
                } footer: {
                    Text("Keep your streaks alive by logging habits before midnight!")
                }
            }
            .navigationTitle("Habit Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ScheduleInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(CardDesign.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(CardDesign.headline)
                Text(description).font(CardDesign.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StreakInfoRow: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("🔥")
                .font(CardDesign.title2)
                .modifier(SheetPulseAnimationModifier())
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text("Streak at Risk").font(CardDesign.headline)
                Text("You have an active streak! Log this habit today to keep it going. The number shows your current streak length.")
                    .font(CardDesign.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pulse Animation Modifiers

struct PulseAnimationModifier: ViewModifier {
    @State private var pulseCount = 0
    @State private var scale: CGFloat = 0.95
    @State private var opacity: Double = 0.65

    private let maxPulses = 2

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear { animatePulse() }
    }

    private func animatePulse() {
        guard pulseCount < maxPulses else {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.2
                opacity = 1.0
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.45)) {
            scale = 1.2
            opacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.45)) {
                scale = 0.95
                opacity = 0.65
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                pulseCount += 1
                animatePulse()
            }
        }
    }
}

struct SheetPulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.7)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

