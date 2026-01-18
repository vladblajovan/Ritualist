//
//  HabitsView+Components.swift
//  Ritualist
//
//  Extracted components from HabitsView to reduce file length.
//

import SwiftUI
import RitualistCore

// MARK: - Over-Limit Banner

struct OverLimitBannerView: View {
    let currentCount: Int
    let maxCount: Int
    let onUpgradeTap: () -> Void

    private var isAtLimit: Bool {
        currentCount >= maxCount
    }

    private var message: String {
        isAtLimit
            ? "Keep the momentum! Unlock Pro for unlimited habits."
            : "Unlock Pro to create unlimited habits and reach your goals faster."
    }

    var body: some View {
        ProUpgradeBanner(
            style: .card(habitCount: currentCount, maxHabits: maxCount, message: message),
            onUnlock: onUpgradeTap
        )
    }
}

// MARK: - First Time Empty State

struct HabitsFirstTimeEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(Strings.EmptyState.noHabitsYet)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text("Tap")
                    Image(systemName: "plus")
                        .fontWeight(.medium)
                    Text("or")
                    Image(systemName: "sparkles")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("to create your first habit")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No habits yet. Tap plus or the AI assistant button to create your first habit.")
    }
}
