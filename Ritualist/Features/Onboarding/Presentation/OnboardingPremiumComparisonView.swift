import SwiftUI
import RitualistCore

struct OnboardingPremiumComparisonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Icon with glow
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "crown.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(.orange)
                }
                .animatedGlow(color: .orange, glowSize: 140, intensity: 0.4)
                .accessibilityHidden(true)

                // Title and description
                VStack(spacing: 8) {
                    Text(Strings.OnboardingPremium.title)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(Strings.OnboardingPremium.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Free vs Pro comparison
                HStack(spacing: 12) {
                    // Free tier
                    PremiumTierCard(
                        title: Strings.OnboardingPremium.freeTier,
                        features: [
                            PremiumFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.fiveHabits, color: .green),
                            PremiumFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.dailyTracking, color: .green),
                            PremiumFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.basicNotifications, color: .green),
                            PremiumFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.tipsInsights, color: .green),
                            PremiumFeature(icon: "icloud.fill", text: Strings.OnboardingPremium.iCloudSync, color: .green)
                        ],
                        isPro: false
                    )

                    // Pro tier
                    PremiumTierCard(
                        title: Strings.OnboardingPremium.proTier,
                        features: [
                            PremiumFeature(icon: "infinity.circle.fill", text: Strings.OnboardingPremium.unlimitedHabits, color: .orange),
                            PremiumFeature(icon: "chart.line.uptrend.xyaxis.circle.fill", text: Strings.OnboardingPremium.advancedAnalytics, color: .orange),
                            PremiumFeature(icon: "bell.badge.circle.fill", text: Strings.OnboardingPremium.customReminders, color: .orange),
                            PremiumFeature(icon: "arrow.up.arrow.down.circle.fill", text: Strings.OnboardingPremium.dataExport, color: .orange)
                        ],
                        isPro: true
                    )
                }
                .padding(.horizontal, 24)

                // Footer text
                Text(Strings.OnboardingPremium.footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Supporting Types

private struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let color: Color
}

private struct PremiumTierCard: View {
    let title: String
    let features: [PremiumFeature]
    let isPro: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 6) {
                if isPro {
                    Image(systemName: "crown.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }

                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(isPro ? .orange : .primary)
            }

            Divider()

            // Features list
            VStack(alignment: .leading, spacing: 6) {
                ForEach(features) { feature in
                    HStack(spacing: 6) {
                        Image(systemName: feature.icon)
                            .font(.caption2)
                            .foregroundStyle(feature.color)
                            .frame(width: 14)

                        Text(feature.text)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isPro ? Color.orange.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isPro ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    OnboardingPremiumComparisonView()
}
