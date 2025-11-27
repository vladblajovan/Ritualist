//
//  ReturningUserOnboardingView.swift
//  Ritualist
//
//  Created by Claude on 27.11.2025.
//
//  Streamlined onboarding flow for returning users with existing iCloud data.
//  Shows welcome back screen, then permissions only (skips name/avatar/habit creation).
//

import SwiftUI
import FactoryKit
import RitualistCore

/// Onboarding flow for returning users with existing iCloud data.
/// Only shows welcome back screen and permissions request.
struct ReturningUserOnboardingView: View {
    let summary: SyncedDataSummary
    let onComplete: () -> Void

    @Injected(\.onboardingViewModel) private var viewModel
    @State private var currentStep: ReturningUserStep = .welcome

    var body: some View {
        Group {
            switch currentStep {
            case .welcome:
                WelcomeBackView(summary: summary) {
                    withAnimation {
                        currentStep = .permissions
                    }
                }

            case .permissions:
                ReturningUserPermissionsView(viewModel: viewModel) {
                    Task {
                        await finishOnboarding()
                    }
                }
            }
        }
        .task {
            // Load initial permission state
            await viewModel.checkPermissions()
        }
    }

    private func finishOnboarding() async {
        // Use the profile name from iCloud if available
        let userName = summary.profileName ?? ""

        // Update the view model with the synced name (if any)
        viewModel.userName = userName

        // Complete onboarding
        let success = await viewModel.finishOnboarding()
        if success {
            onComplete()
        }
    }
}

// MARK: - Step Enum

private enum ReturningUserStep {
    case welcome
    case permissions
}

// MARK: - Permissions View

/// Permissions request view for returning users.
/// Streamlined version focused only on requesting device permissions.
struct ReturningUserPermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Permission icons
            HStack(spacing: 24) {
                PermissionIcon(
                    icon: viewModel.hasGrantedNotifications ? "bell.fill" : "bell.slash.fill",
                    color: viewModel.hasGrantedNotifications ? .blue : .secondary,
                    isGranted: viewModel.hasGrantedNotifications
                )

                PermissionIcon(
                    icon: viewModel.hasGrantedLocation ? "location.fill" : "location.slash.fill",
                    color: viewModel.hasGrantedLocation ? .green : .secondary,
                    isGranted: viewModel.hasGrantedLocation
                )
            }

            // Title
            VStack(spacing: 8) {
                Text("Set Up This Device")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Enable permissions to get the most out of your habits")
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
                    isGranted: viewModel.hasGrantedNotifications,
                    action: {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    }
                )

                PermissionCard(
                    icon: "location.fill",
                    iconColor: .green,
                    title: "Location",
                    description: "Enable location-based habit reminders",
                    isGranted: viewModel.hasGrantedLocation,
                    action: {
                        Task {
                            await viewModel.requestLocationPermission()
                        }
                    }
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            VStack(spacing: 8) {
                Button(action: onComplete) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !viewModel.hasGrantedNotifications || !viewModel.hasGrantedLocation {
                    Text("You can enable these later in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Helper Views

private struct PermissionIcon: View {
    let icon: String
    let color: Color
    let isGranted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 70, height: 70)

            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(color)
        }
        .overlay(alignment: .bottomTrailing) {
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
                    .background(Circle().fill(.white).padding(2))
            }
        }
        .animation(.easeInOut, value: isGranted)
    }
}

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
    }
}

#Preview {
    ReturningUserOnboardingView(
        summary: SyncedDataSummary(
            habitsCount: 8,
            categoriesCount: 2,
            hasProfile: true,
            profileName: "John",
            profileAvatar: nil
        ),
        onComplete: {}
    )
}
