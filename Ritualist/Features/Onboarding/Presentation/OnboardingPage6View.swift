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
                .accessibilityLabel("Notifications")
                .accessibilityValue(viewModel.hasGrantedNotifications ? "Enabled" : "Not enabled")

                PermissionIcon(
                    icon: viewModel.hasGrantedLocation ? "location.fill" : "location.slash.fill",
                    color: viewModel.hasGrantedLocation ? .green : .secondary,
                    isGranted: viewModel.hasGrantedLocation
                )
                .accessibilityLabel("Location")
                .accessibilityValue(viewModel.hasGrantedLocation ? "Enabled" : "Not enabled")
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
                    title: "Notifications",
                    description: "Get reminders for your habits at the right time",
                    isGranted: viewModel.hasGrantedNotifications
                ) {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }

                PermissionCard(
                    icon: "location.fill",
                    iconColor: .green,
                    title: "Location",
                    description: "Enable location-based habit reminders",
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
                            Text("Quick Tour")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Learn the basics with helpful tips")
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
            .alert("Skip Quick Tour?", isPresented: $viewModel.showSkipTrainingAlert) {
                Button("Skip", role: .destructive) {
                    viewModel.confirmSkipTraining()
                }
                Button("Keep Tour", role: .cancel) {
                    viewModel.cancelSkipTraining()
                }
            } message: {
                Text("The quick tour shows helpful tips as you explore the app. You can always find help in Settings later.")
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
                Button("Enable") {
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
        .accessibilityValue(isGranted ? "Enabled" : "Not enabled")
        .accessibilityHint(isGranted ? "" : "Double tap to enable \(title.lowercased())")
    }
}