//
//  PersonalityInsightsUpsellCard.swift
//  Ritualist
//
//  Marketing card shown to free users with sufficient data for personality analysis.
//  Encourages upgrade to unlock personality insights.
//

import SwiftUI
import RitualistCore

struct PersonalityInsightsUpsellCard: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header with premium gradient
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Personality Insights")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Premium Feature")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CrownProBadge()
            }

            // Marketing content
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("You've built enough habits for us to analyze your unique personality profile!")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Benefits list
                VStack(alignment: .leading, spacing: 8) {
                    benefitRow(icon: "sparkles", text: "Discover your habit personality type")
                    benefitRow(icon: "lightbulb.fill", text: "Get personalized recommendations")
                    benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Understand your motivation patterns")
                }
                .padding(.top, 4)
            }

            // CTA Button
            Button(action: onUnlock) {
                HStack {
                    Image(systemName: "lock.open.fill")
                        .font(.subheadline)
                    Text("Unlock with Pro")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(GradientTokens.purchaseButton)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.purple)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Upsell Card") {
    PersonalityInsightsUpsellCard(onUnlock: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}
