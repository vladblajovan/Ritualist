import SwiftUI
import RitualistCore

struct OnboardingPage4View: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)

                // Icon with glow
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lightbulb.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(.orange)
                }
                .animatedGlow(color: .orange, glowSize: 140, intensity: 0.4)
                .accessibilityHidden(true)

                // Title and description
                VStack(spacing: 8) {
                    Text(Strings.Onboarding.learnImproveTitle)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(Strings.Onboarding.learnImproveSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Feature cards
                VStack(spacing: 12) {
                    OnboardingFeatureCard(
                        icon: "book.fill",
                        iconColor: .orange,
                        title: Strings.Onboarding.scienceBasedTipsTitle,
                        description: Strings.Onboarding.scienceBasedTipsDescription
                    )

                    OnboardingFeatureCard(
                        icon: "chart.bar.fill",
                        iconColor: .yellow,
                        title: Strings.Onboarding.trackProgressTitle,
                        description: Strings.Onboarding.trackProgressDescription
                    )

                    OnboardingFeatureCard(
                        icon: "arrow.up.right.circle.fill",
                        iconColor: .red,
                        title: Strings.Onboarding.stayMotivatedTitle,
                        description: Strings.Onboarding.stayMotivatedDescription
                    )

                    OnboardingFeatureCard(
                        icon: "airplane.circle.fill",
                        iconColor: .teal,
                        title: Strings.Onboarding.travelInsightsTitle,
                        description: Strings.Onboarding.travelInsightsDescription
                    )
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
    }
}