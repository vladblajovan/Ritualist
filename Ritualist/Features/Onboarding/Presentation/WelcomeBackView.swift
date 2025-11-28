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
                Text("Welcome back,")
                    .font(.system(.title, design: .rounded, weight: .bold))

                if let name = summary.profileName, !name.isEmpty {
                    Text("\(name)!")
                        .font(.system(.title, design: .rounded, weight: .bold))
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
        }
    }

    private var syncedDataCard: some View {
        VStack(spacing: 16) {
            if summary.habitsCount > 0 {
                SyncedItemRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    text: "\(summary.habitsCount) habit\(summary.habitsCount == 1 ? "" : "s") synced"
                )
            }

            if summary.categoriesCount > 0 {
                SyncedItemRow(
                    icon: "folder.fill",
                    iconColor: .blue,
                    text: "\(summary.categoriesCount) custom categor\(summary.categoriesCount == 1 ? "y" : "ies") synced"
                )
            }

            if summary.hasProfile {
                SyncedItemRow(
                    icon: "person.crop.circle.fill",
                    iconColor: .purple,
                    text: "Profile restored"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Helper Views

private struct SyncedItemRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()
        }
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
