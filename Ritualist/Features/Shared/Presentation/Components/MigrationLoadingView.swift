//
//  MigrationLoadingView.swift
//  Ritualist
//
//  Created by Claude on 03.11.2025.
//
//  Full-screen modal overlay shown during database schema migrations.
//  Auto-dismisses when migration completes successfully.
//

import SwiftUI
import RitualistCore

/// Full-screen loading modal shown during database migrations
///
/// This view provides user feedback during schema migrations and prevents
/// interaction with the app until the migration completes.
///
/// Usage:
/// ```swift
/// .overlay {
///     if migrationService.isMigrating {
///         MigrationLoadingView(details: migrationService.migrationDetails)
///     }
/// }
/// ```
public struct MigrationLoadingView: View {
    let details: MigrationDetails?

    public init(details: MigrationDetails? = nil) {
        self.details = details
    }

    public var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Content card
            VStack(spacing: Spacing.large) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.brand.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "cylinder.split.1x2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.brand)
                }
                .padding(.bottom, Spacing.small)

                // Title
                Text("Preparing Your Experience")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                // Migration details (if available)
                if let details = details {
                    Text(details.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.medium)
                }

                // Loading indicator
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppColors.brand)
                    .padding(.top, Spacing.small)

                // Helpful message
                Text("This will only take a moment")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, Spacing.small)
            }
            .padding(Spacing.screenMargin)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, Spacing.screenMargin)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Preview

#Preview("Migration Loading") {
    MigrationLoadingView(
        details: MigrationDetails(
            fromVersion: "4.0.0",
            toVersion: "5.0.0",
            startTime: Date()
        )
    )
}

#Preview("Without Details") {
    MigrationLoadingView()
}
