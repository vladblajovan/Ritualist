//
//  ReturningUserOnboardingView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 27.11.2025.
//
//  Streamlined onboarding flow for returning users with existing iCloud data.
//  Shows welcome back screen, then permissions only (skips name/avatar/habit creation).
//

import SwiftUI
import FactoryKit
import RitualistCore

/// Onboarding flow for returning users with existing iCloud data.
/// Shows welcome back screen, profile completion (if needed), then permissions request.
struct ReturningUserOnboardingView: View {
    let summary: SyncedDataSummary
    let onComplete: () -> Void

    @Injected(\.onboardingViewModel) private var viewModel
    @Injected(\.debugLogger) private var logger
    @State private var currentStep: ReturningUserStep = .welcome

    var body: some View {
        Group {
            switch currentStep {
            case .welcome:
                WelcomeBackView(summary: summary) {
                    withAnimation {
                        // Go to profile completion if needed, otherwise skip to permissions
                        currentStep = summary.needsProfileCompletion ? .profileCompletion : .permissions
                    }
                }

            case .profileCompletion:
                ReturningUserProfileCompletionView(
                    summary: summary,
                    viewModel: viewModel
                ) {
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

            // Pre-populate view model with existing profile data
            if let name = summary.profileName, !name.isEmpty {
                viewModel.userName = name
            }
            if let genderRaw = summary.profileGender {
                if let parsedGender = UserGender(rawValue: genderRaw) {
                    viewModel.gender = parsedGender
                } else {
                    logger.log(
                        "Failed to parse gender from iCloud data",
                        level: .warning,
                        category: .dataIntegrity,
                        metadata: ["raw_value": genderRaw]
                    )
                }
            }
            if let ageGroupRaw = summary.profileAgeGroup {
                if let parsedAgeGroup = UserAgeGroup(rawValue: ageGroupRaw) {
                    viewModel.ageGroup = parsedAgeGroup
                } else {
                    logger.log(
                        "Failed to parse age group from iCloud data",
                        level: .warning,
                        category: .dataIntegrity,
                        metadata: ["raw_value": ageGroupRaw]
                    )
                }
            }
        }
        .onChange(of: currentStep) { _, newStep in
            announceStepChange(newStep)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred")
        }
    }

    /// Announces step change to VoiceOver users
    private func announceStepChange(_ step: ReturningUserStep) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        let stepTitle = switch step {
        case .welcome: "Welcome Back"
        case .profileCompletion: "Complete Your Profile"
        case .permissions: "Set Up This Device"
        }
        UIAccessibility.post(notification: .screenChanged, argument: stepTitle)
    }

    private func finishOnboarding() async {
        // Complete onboarding with the (possibly updated) profile data
        let success = await viewModel.finishOnboarding()
        if success {
            onComplete()
        }
    }
}

// MARK: - Step Enum

private enum ReturningUserStep {
    case welcome
    case profileCompletion
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

            // Title
            VStack(spacing: 8) {
                Text("Set Up This Device")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

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
                .accessibilityHint("Complete setup and start using Ritualist")

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
                .font(.title)
                .foregroundStyle(color)
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

// MARK: - Profile Completion View

/// Profile completion view for returning users with missing data.
/// Collects name, gender, and age group if not already set.
struct ReturningUserProfileCompletionView: View {
    let summary: SyncedDataSummary
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    /// Whether name input is needed
    private var needsName: Bool {
        summary.profileName?.isEmpty ?? true
    }

    /// Whether the continue button should be enabled
    private var canContinue: Bool {
        // If we need a name, make sure it's filled in
        if needsName {
            return !viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.brand)
            }

            // Title and subtitle
            VStack(spacing: 8) {
                Text("Complete Your Profile")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Help us personalize your experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Profile inputs
            VStack(spacing: 16) {
                // Name input (only if missing)
                if needsName {
                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("What should we call you?", text: $viewModel.userName)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(AppColors.brand)
                            .multilineTextAlignment(.center)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                isTextFieldFocused = false
                            }
                            .accessibilityLabel("Name")
                            .accessibilityHint("Enter your name to personalize your experience. Maximum \(OnboardingViewModel.maxNameLength) characters.")
                            .modifier(ProfileFieldStyle())

                        // Character count (only show when approaching limit)
                        if viewModel.userName.count > OnboardingViewModel.maxNameLength - 10 {
                            Text("\(viewModel.userName.count)/\(OnboardingViewModel.maxNameLength)")
                                .font(.caption2)
                                .foregroundStyle(
                                    viewModel.userName.count >= OnboardingViewModel.maxNameLength
                                        ? .red
                                        : .secondary
                                )
                                .padding(.trailing, 8)
                                .accessibilityLabel("\(viewModel.userName.count) of \(OnboardingViewModel.maxNameLength) characters used")
                        }
                    }
                }

                // Gender and Age Group selectors
                HStack(spacing: 12) {
                    // Gender picker
                    Menu {
                        ForEach(UserGender.allCases) { gender in
                            Button(gender.displayName) {
                                viewModel.gender = gender
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.gender == .preferNotToSay ? "Gender" : viewModel.gender.displayName)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(viewModel.gender == .preferNotToSay ? .secondary : AppColors.brand)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .modifier(ProfileFieldStyle())
                    }
                    .accessibilityLabel("Gender")
                    .accessibilityValue(viewModel.gender.displayName)

                    // Age group picker
                    Menu {
                        ForEach(UserAgeGroup.allCases) { ageGroup in
                            Button(ageGroup.displayName) {
                                viewModel.ageGroup = ageGroup
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.ageGroup == .preferNotToSay ? "Age" : viewModel.ageGroup.displayName)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(viewModel.ageGroup == .preferNotToSay ? .secondary : AppColors.brand)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .modifier(ProfileFieldStyle())
                    }
                    .accessibilityLabel("Age group")
                    .accessibilityValue(viewModel.ageGroup.displayName)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canContinue ? AppColors.brand : AppColors.brand.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canContinue)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .accessibilityHint(canContinue ? "Continue to permissions setup" : "Enter your name to continue")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onAppear {
            if needsName {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

/// Field style for profile inputs
private struct ProfileFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppColors.brand.opacity(0.4),
                                AppColors.brand.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
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
            profileAvatar: nil,
            profileGender: nil,
            profileAgeGroup: nil
        ),
        onComplete: {}
    )
}
