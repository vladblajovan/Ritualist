//
//  ProUpgradeBanner.swift
//  Ritualist
//
//  Reusable upgrade banner component for promoting premium features.
//

import SwiftUI
import RitualistCore

/// Reusable upgrade banner with crown PRO badge and unlock button
///
/// Supports two styles:
/// - `.card`: Full card with optional habit count, message, and full-width button
/// - `.row`: Compact list row style with title/subtitle and inline button
///
/// Usage:
/// ```swift
/// // Card style with habit count
/// ProUpgradeBanner(
///     style: .card(habitCount: 3, maxHabits: 5),
///     message: "Unlock Pro to create unlimited habits.",
///     onUnlock: { showPaywall() }
/// )
///
/// // Card style without habit count
/// ProUpgradeBanner(
///     style: .card(),
///     message: "Unlock Pro for premium features.",
///     onUnlock: { showPaywall() }
/// )
///
/// // Row style for Settings lists
/// ProUpgradeBanner(
///     style: .row(title: "Unlock all features", subtitle: "Get unlimited habits and more"),
///     onUnlock: { showPaywall() }
/// )
/// ```
struct ProUpgradeBanner: View {
    let style: Style
    let onUnlock: () -> Void

    enum Style {
        /// Card style with optional habit count display
        case card(habitCount: Int? = nil, maxHabits: Int? = nil, message: String)
        /// Compact row style for Settings lists
        case row(title: String, subtitle: String?)
    }

    var body: some View {
        switch style {
        case .card(let habitCount, let maxHabits, let message):
            cardStyle(habitCount: habitCount, maxHabits: maxHabits, message: message)
        case .row(let title, let subtitle):
            rowStyle(title: title, subtitle: subtitle)
        }
    }

    // MARK: - Card Style

    @ViewBuilder
    private func cardStyle(habitCount: Int?, maxHabits: Int?, message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header row with optional habit count and PRO badge
            HStack {
                if let count = habitCount, let max = maxHabits {
                    Text("\(count)/\(max) habits")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                Spacer()

                CrownProBadge()
            }

            // Message
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Unlock button
            Button(action: onUnlock) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.caption)
                    Text("Unlock with Pro")
                        .font(.subheadline)
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
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Row Style

    @ViewBuilder
    private func rowStyle(title: String, subtitle: String?) -> some View {
        Button(action: onUnlock) {
            HStack {
                // Use Label for consistent icon/text alignment with other rows
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if let subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(GradientTokens.premiumCrown)
                }

                Spacer()

                // Unlock button
                HStack(spacing: 4) {
                    Image(systemName: "lock.open.fill")
                        .font(.caption2)
                    Text("Unlock")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(GradientTokens.purchaseButton)
                .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Card - With Habit Count") {
    VStack {
        ProUpgradeBanner(
            style: .card(
                habitCount: 3,
                maxHabits: 5,
                message: "Unlock Pro to create unlimited habits and reach your goals faster."
            ),
            onUnlock: {}
        )
        .padding()

        Spacer()
    }
}

#Preview("Card - At Limit") {
    VStack {
        ProUpgradeBanner(
            style: .card(
                habitCount: 5,
                maxHabits: 5,
                message: "Keep the momentum! Unlock Pro for unlimited habits."
            ),
            onUnlock: {}
        )
        .padding()

        Spacer()
    }
}

#Preview("Card - No Habit Count") {
    VStack {
        ProUpgradeBanner(
            style: .card(message: "Unlock Pro for premium features and insights."),
            onUnlock: {}
        )
        .padding()

        Spacer()
    }
}

#Preview("Row Style") {
    List {
        Section {
            ProUpgradeBanner(
                style: .row(
                    title: "Unlock all features",
                    subtitle: "Get unlimited habits, insights, and more"
                ),
                onUnlock: {}
            )
        }
    }
}
