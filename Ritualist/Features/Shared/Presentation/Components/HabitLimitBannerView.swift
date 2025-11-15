//
//  HabitLimitBannerView.swift
//  Ritualist
//
//  Created on 2025-11-10.
//

import SwiftUI
import RitualistCore

/// Banner component that displays habit count and limit for free users
/// Shows dynamic counter (e.g., "3/5 habits") and upgrade option
struct HabitLimitBannerView: View {
    let currentCount: Int
    let maxCount: Int
    let onUpgradeTap: () -> Void

    private var isAtLimit: Bool {
        currentCount >= maxCount
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Info icon - changes color when at limit
            Image(systemName: isAtLimit ? "exclamationmark.circle.fill" : "info.circle.fill")
                .font(.title3)
                .foregroundStyle(isAtLimit ? .orange : .blue)

            // Message
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                Text("\(currentCount)/\(maxCount) habits (Free)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(isAtLimit
                     ? "Limit reached. Upgrade to Pro for unlimited habits"
                     : "Upgrade to Pro for unlimited habits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Upgrade button
            Button(action: onUpgradeTap) {
                Text("Upgrade")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke((isAtLimit ? Color.orange : Color.blue).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Under Limit") {
    VStack {
        HabitLimitBannerView(
            currentCount: 3,
            maxCount: 5,
            onUpgradeTap: { }
        )
        .padding()

        Spacer()
    }
}

#Preview("At Limit") {
    VStack {
        HabitLimitBannerView(
            currentCount: 5,
            maxCount: 5,
            onUpgradeTap: { }
        )
        .padding()

        Spacer()
    }
}
