import SwiftUI
import RitualistCore

struct OnboardingPage3View: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)

                // Icon with glow
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "paintbrush.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(.purple)
                }
                .animatedGlow(color: .purple, glowSize: 140, intensity: 0.4)
                .accessibilityHidden(true)

                // Title and description
                VStack(spacing: 8) {
                    Text(Strings.Onboarding.makeItYoursTitle)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(Strings.Onboarding.makeItYoursSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Feature cards
                VStack(spacing: 12) {
                    OnboardingFeatureCard(
                        icon: "paintpalette.fill",
                        iconColor: .pink,
                        title: Strings.Onboarding.colorsEmojisTitle,
                        description: Strings.Onboarding.colorsEmojisDescription
                    )

                    OnboardingFeatureCard(
                        icon: "calendar",
                        iconColor: .purple,
                        title: Strings.Onboarding.flexibleSchedulingTitle,
                        description: Strings.Onboarding.flexibleSchedulingDescription
                    )

                    OnboardingFeatureCard(
                        icon: "target",
                        iconColor: .indigo,
                        title: Strings.Onboarding.setGoalsTitle,
                        description: Strings.Onboarding.setGoalsDescription
                    )

                    OnboardingFeatureCard(
                        icon: "airplane",
                        iconColor: .blue,
                        title: Strings.Onboarding.travelFriendlyTitle,
                        description: Strings.Onboarding.travelFriendlyDescription
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
