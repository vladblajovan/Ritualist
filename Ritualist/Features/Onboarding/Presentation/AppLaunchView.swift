//
//  AppLaunchView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 27.11.2025.
//
//  Branded launch screen shown while detecting iCloud data.
//  Provides a seamless transition from the iOS launch screen.
//

import SwiftUI
import RitualistCore

/// Branded launch screen with app icon and loading spinner.
/// Shown during initial iCloud data detection on fresh install,
/// and during database migrations for a seamless experience.
struct AppLaunchView: View {
    /// Optional migration details to show during schema upgrades
    var migrationDetails: MigrationDetails?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon - using dedicated high-res asset for crisp display
            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .animatedGlow(glowSize: 220)
                .accessibilityLabel("Ritualist app icon")

            // App name with brand gradient
            Text("Ritualist")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ritualistIconBackground, AppColors.brand],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            // Migration status or loading spinner
            VStack(spacing: 16) {
                if migrationDetails != nil {
                    // Show migration-specific messaging
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(AppColors.brand)

                    Text(Strings.Onboarding.preparingExperience)
                        .font(CardDesign.headline)
                        .foregroundStyle(.primary)

                    #if DEBUG
                    if let details = migrationDetails {
                        Text(details.description)
                            .font(CardDesign.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    #endif

                    Text(Strings.Onboarding.onlyTakesMoment)
                        .font(CardDesign.caption)
                        .foregroundStyle(.secondary.opacity(0.7))
                } else {
                    // Default loading spinner
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppColors.brand)
                        .accessibilityLabel(Strings.Onboarding.loading)
                }
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(migrationDetails != nil ? Strings.Onboarding.preparingAccessibility : Strings.Onboarding.loadingAccessibility)
    }
}

#Preview("Loading") {
    AppLaunchView()
}

#Preview("Migration") {
    AppLaunchView(
        migrationDetails: MigrationDetails(
            fromVersion: "9",
            toVersion: "10",
            startTime: Date()
        )
    )
}
