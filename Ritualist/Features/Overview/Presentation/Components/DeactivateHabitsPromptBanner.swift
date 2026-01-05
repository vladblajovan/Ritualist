//
//  DeactivateHabitsPromptBanner.swift
//  Ritualist
//
//  Banner shown when a free user has more active habits than the free tier allows.
//  Typically appears when a premium user's subscription expires.
//

import SwiftUI
import RitualistCore

/// Banner prompting users to deactivate habits or upgrade when over the free tier limit.
///
/// This banner is shown when:
/// - User is on the free tier
/// - User has more than `BusinessConstants.freeMaxHabits` active habits
///
/// The banner does NOT block habit logging - users can still log all their habits.
/// It simply prompts them to either deactivate some habits or upgrade to Pro.
struct DeactivateHabitsPromptBanner: View {
    let activeCount: Int
    let maxFreeHabits: Int
    let onManageHabits: () -> Void
    let onUpgrade: () -> Void

    private var excessCount: Int {
        max(0, activeCount - maxFreeHabits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header with warning icon
            HStack(spacing: Spacing.small) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(CardDesign.title3)

                Text("Too Many Active Habits")
                    .font(CardDesign.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // Explanation text
            Text("Free plan allows \(maxFreeHabits) habits. Deactivate \(excessCount) or upgrade.")
                .font(CardDesign.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Action buttons
            HStack(spacing: Spacing.small) {
                // Manage Habits button
                Button(action: onManageHabits) {
                    Text("Manage Habits")
                        .font(CardDesign.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.small)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: CardDesign.innerCornerRadius))
                }
                .buttonStyle(.plain)

                // Upgrade button
                Button(action: onUpgrade) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(CardDesign.caption)
                        Text("Upgrade")
                            .font(CardDesign.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.small)
                    .background(GradientTokens.purchaseButton)
                    .clipShape(RoundedRectangle(cornerRadius: CardDesign.innerCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
        )
    }
}

// MARK: - Previews

#Preview("Over by 1") {
    VStack {
        DeactivateHabitsPromptBanner(
            activeCount: 6,
            maxFreeHabits: 5,
            onManageHabits: {},
            onUpgrade: {}
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Over by 3") {
    VStack {
        DeactivateHabitsPromptBanner(
            activeCount: 8,
            maxFreeHabits: 5,
            onManageHabits: {},
            onUpgrade: {}
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
