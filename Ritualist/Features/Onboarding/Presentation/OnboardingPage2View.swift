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
                    Text(Strings.Onboarding.trackHabitsTitle)
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
                        title: Strings.Onboarding.dailyTrackingTitle,
                        description: Strings.Onboarding.dailyTrackingDescription
                    )

                    OnboardingFeatureCard(
                        icon: "chart.bar.fill",
                        iconColor: .purple,
                        title: Strings.Onboarding.progressVisualizationTitle,
                        description: Strings.Onboarding.progressVisualizationDescription
                    )

                    OnboardingFeatureCard(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: Strings.Onboarding.smartRemindersTitle,
                        description: Strings.Onboarding.smartRemindersDescription
                    )

                    OnboardingFeatureCard(
                        icon: "icloud.fill",
                        iconColor: .cyan,
                        title: Strings.Onboarding.iCloudSyncTitle,
                        description: Strings.Onboarding.iCloudSyncDescription
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
        if !viewModel.userName.isEmpty {
            return Strings.Onboarding.trackHabitsGreeting(viewModel.userName)
        } else {
            return Strings.Onboarding.trackHabitsSubtitle
        }
    }
}