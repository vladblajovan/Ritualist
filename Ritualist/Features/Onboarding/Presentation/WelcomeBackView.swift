//
//  WelcomeBackView.swift
//  Ritualist
//
//  Created by Claude on 27.11.2025.
//
//  Welcome screen for returning users with existing iCloud data.
//  Shows personalized greeting with synced data summary.
//

import SwiftUI
import RitualistCore

/// Welcome back screen for returning users with synced iCloud data.
/// Shows personalized greeting and data summary before requesting permissions.
struct WelcomeBackView: View {
    let summary: SyncedDataSummary
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Avatar or default icon
            avatarSection

            // Welcome message
            VStack(spacing: 4) {
                if let name = summary.profileName, !name.isEmpty {
                    Text("Welcome back,")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    Text("\(name)!")
                        .font(.system(.title, design: .rounded, weight: .bold))
                } else {
                    Text("Welcome back!")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                }

                Text("Your data has been synced from iCloud")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            // Synced data summary
            syncedDataCard

            Spacer()

            // Continue button
            VStack(spacing: 12) {
                Text("Let's set up this device")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityHint("Continue to set up this device")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    /// App icon for branding (consistent with AppLaunchView)
    @ViewBuilder
    private var appIconSection: some View {
        if let uiImage = Bundle.main.appIcon {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: AppColors.brand.opacity(0.3), radius: 15, x: 0, y: 8)
        }
    }

    @ViewBuilder
    private var avatarSection: some View {
        if let avatarData = summary.profileAvatar,
           let uiImage = UIImage(data: avatarData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.brand, lineWidth: 3)
                )
                .animatedGlow(glowSize: 160)
                .accessibilityLabel("Your profile photo")
        } else {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.brand, AppColors.brand.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.white)
            }
            .animatedGlow(glowSize: 160)
            .accessibilityHidden(true)
        }
    }

    private var syncedDataCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.icloud.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 28)
                .accessibilityHidden(true)

            Text("Your data has been synced and the app is ready to use")
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your data has been synced and the app is ready to use")
    }
}

#Preview("With Name and Avatar") {
    WelcomeBackView(
        summary: SyncedDataSummary(
            habitsCount: 12,
            categoriesCount: 3,
            hasProfile: true,
            profileName: "John",
            profileAvatar: nil
        ),
        onContinue: {}
    )
}

#Preview("Without Name") {
    WelcomeBackView(
        summary: SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 0,
            hasProfile: false,
            profileName: nil,
            profileAvatar: nil
        ),
        onContinue: {}
    )
}
