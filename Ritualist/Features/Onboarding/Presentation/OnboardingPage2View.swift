import SwiftUI
import RitualistCore

struct OnboardingPage2View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)

                // Icon with glow
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(.green)
                }
                .animatedGlow(color: .green, glowSize: 140, intensity: 0.4)

                // Title and description
                VStack(spacing: 8) {
                    Text("Track Your Habits")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

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

                // Info badge
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(AppColors.brand)

                    Text("Free: 5 habits")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Pro: unlimited")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

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