import SwiftUI
import RitualistCore

struct OnboardingPage6View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Permission icons with animation
                HStack(spacing: 24) {
                    PermissionIcon(
                        icon: "bell.fill",
                        color: .blue,
                        isGranted: viewModel.hasGrantedNotifications
                    )

                    PermissionIcon(
                        icon: "location.fill",
                        color: .green,
                        isGranted: viewModel.hasGrantedLocation
                    )
                }

                // Title and description
                VStack(spacing: 8) {
                    Text(Strings.OnboardingPermissions.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(Strings.OnboardingPermissions.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Permission cards
                VStack(spacing: 12) {
                    PermissionCard(
                        icon: "bell.badge.fill",
                        iconColor: .blue,
                        title: "Notifications",
                        description: "Get timely reminders for your habits",
                        isGranted: viewModel.hasGrantedNotifications,
                        grantedText: Strings.OnboardingPermissions.notificationsGranted,
                        buttonText: Strings.OnboardingPermissions.enableNotifications
                    ) {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    }

                    PermissionCard(
                        icon: "location.fill",
                        iconColor: .green,
                        title: "Location",
                        description: "Get reminders when you arrive at places",
                        isGranted: viewModel.hasGrantedLocation,
                        grantedText: Strings.OnboardingPermissions.locationGranted,
                        buttonText: Strings.OnboardingPermissions.enableLocation
                    ) {
                        Task {
                            await viewModel.requestLocationPermission()
                        }
                    }
                }
                .padding(.horizontal, 24)

                if !viewModel.hasGrantedNotifications || !viewModel.hasGrantedLocation {
                    Text(Strings.OnboardingPermissions.skipForNow)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
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
                .font(.system(size: 30))
                .foregroundStyle(isGranted ? color : .secondary)
        }
        .overlay(alignment: .bottomTrailing) {
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
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
    let grantedText: String
    let buttonText: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                if isGranted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(grantedText)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Button
            if !isGranted {
                Button(action: action) {
                    Text("Enable")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(iconColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .animation(.easeInOut, value: isGranted)
    }
}