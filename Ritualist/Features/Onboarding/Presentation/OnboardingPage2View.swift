import SwiftUI
import RitualistCore

struct OnboardingPage2View: View {
    @Bindable var viewModel: OnboardingViewModel

    // Scale icon container with Dynamic Type
    @ScaledMetric(relativeTo: .largeTitle) private var iconContainerSize: CGFloat = 100
    @ScaledMetric(relativeTo: .largeTitle) private var glowSize: CGFloat = 140

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)

                // Icon with glow - scales with Dynamic Type
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: iconContainerSize, height: iconContainerSize)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(.green)
                }
                .animatedGlow(color: .green, glowSize: glowSize, intensity: 0.4)
                .accessibilityHidden(true)

                // Title and description
                VStack(spacing: 8) {
                    Text("Track Your Habits")
                        .font(.title.weight(.bold))
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(personalizedGreeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Feature cards
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
                        description: "See your streaks and patterns over time"
                    )

                    OnboardingFeatureCard(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Smart Reminders",
                        description: "Get notified when it's time for your habits"
                    )
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
    }

    private var personalizedGreeting: String {
        let baseMessage = "Build lasting habits with visual progress tracking and smart reminders."

        if !viewModel.userName.isEmpty {
            return "Hi \(viewModel.userName)! \(baseMessage)"
        } else {
            return baseMessage
        }
    }
}