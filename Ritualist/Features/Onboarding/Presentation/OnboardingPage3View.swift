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
                    Text("Make It Yours")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Customize your habits with colors, emojis, and flexible scheduling.")
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
                        title: "Colors & Emojis",
                        description: "Personalize each habit with colors and emojis"
                    )

                    OnboardingFeatureCard(
                        icon: "calendar",
                        iconColor: .purple,
                        title: "Flexible Scheduling",
                        description: "Daily, weekly, or custom schedules that fit you"
                    )

                    OnboardingFeatureCard(
                        icon: "target",
                        iconColor: .indigo,
                        title: "Set Your Goals",
                        description: "Binary tracking or numeric targets with units"
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
