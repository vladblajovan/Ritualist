//
//  OnboardingFeatureCard.swift
//  Ritualist
//
//  Created by Claude on 27.11.2025.
//
//  Reusable feature card for onboarding pages.
//

import SwiftUI

struct OnboardingFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

#Preview {
    VStack(spacing: 12) {
        OnboardingFeatureCard(
            icon: "calendar",
            iconColor: .blue,
            title: "Daily Tracking",
            description: "Mark habits as complete each day"
        )

        OnboardingFeatureCard(
            icon: "chart.bar.fill",
            iconColor: .purple,
            title: "Progress Visualization",
            description: "See your streaks and patterns"
        )

        OnboardingFeatureCard(
            icon: "bell.fill",
            iconColor: .orange,
            title: "Smart Reminders",
            description: "Get notified at the right time"
        )
    }
    .padding()
}
