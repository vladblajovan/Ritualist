import SwiftUI
import RitualistCore

struct OnboardingPage6View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Permission icons with dynamic state
            HStack(spacing: 24) {
                PermissionIcon(
                    icon: viewModel.hasGrantedNotifications ? "bell.fill" : "bell.slash.fill",
                    color: viewModel.hasGrantedNotifications ? .blue : .secondary,
                    isGranted: viewModel.hasGrantedNotifications
                )
                .accessibilityLabel(Strings.Onboarding.notificationsTitle)
                .accessibilityValue(viewModel.hasGrantedNotifications ? Strings.Onboarding.enabled : Strings.Onboarding.notEnabled)

                PermissionIcon(
                    icon: viewModel.hasGrantedLocation ? "location.fill" : "location.slash.fill",
                    color: viewModel.hasGrantedLocation ? .green : .secondary,
                    isGranted: viewModel.hasGrantedLocation
                )
                .accessibilityLabel(Strings.Onboarding.locationTitle)
                .accessibilityValue(viewModel.hasGrantedLocation ? Strings.Onboarding.enabled : Strings.Onboarding.notEnabled)
            }

            // Title and description
            VStack(spacing: 8) {
                Text(Strings.OnboardingPermissions.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(Strings.OnboardingPermissions.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Permission cards
            VStack(spacing: 16) {
                PermissionCard(
                    icon: "bell.fill",
                    iconColor: .blue,
                    title: Strings.Onboarding.notificationsTitle,
                    description: Strings.Onboarding.notificationsDescription,
                    isGranted: viewModel.hasGrantedNotifications
                ) {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }

                PermissionCard(
                    icon: "location.fill",
                    iconColor: .green,
                    title: Strings.Onboarding.locationTitle,
                    description: Strings.Onboarding.locationDescription,
                    isGranted: viewModel.hasGrantedLocation
                ) {
                    Task {
                        await viewModel.requestLocationPermission()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Training tour toggle
            VStack(spacing: 8) {
                Toggle(isOn: Binding(
                    get: { viewModel.wantsTrainingTour },
                    set: { _ in viewModel.toggleTrainingTour() }
                )) {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.Onboarding.quickTour)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(Strings.Onboarding.quickTourDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 24)
            }
            .alert(Strings.Onboarding.skipQuickTourTitle, isPresented: $viewModel.showSkipTrainingAlert) {
                Button(Strings.Onboarding.skip, role: .destructive) {
                    viewModel.confirmSkipTraining()
                }
                Button(Strings.Onboarding.keepTour, role: .cancel) {
                    viewModel.cancelSkipTraining()
                }
            } message: {
                Text(Strings.Onboarding.skipQuickTourMessage)
            }

            if !viewModel.hasGrantedNotifications || !viewModel.hasGrantedLocation {
                Text(Strings.OnboardingPermissions.skipForNow)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.checkPermissions()
        }
    }
}

// MARK: - Permission Icon

private struct PermissionIcon: View {
    let icon: String
    let color: Color
    let isGranted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isGranted ? 0.15 : 0.08))
                .frame(width: 70, height: 70)

            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(isGranted ? color : .secondary)
        }
        .overlay(alignment: .bottomTrailing) {
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .background(Circle().fill(.white).padding(2))
            }
        }
        .animation(.easeInOut, value: isGranted)
    }
}

// MARK: - Permission Card

private struct PermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                Button(Strings.Onboarding.enable) {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityValue(isGranted ? Strings.Onboarding.enabled : Strings.Onboarding.notEnabled)
        .accessibilityHint(isGranted ? "" : String(format: String(localized: "onboarding.enableHint"), title.lowercased()))
    }
}