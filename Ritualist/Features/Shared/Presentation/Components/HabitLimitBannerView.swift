//
//  HabitLimitBannerView.swift
//  Ritualist
//
//  Created on 2025-11-10.
//

import SwiftUI
import RitualistCore

/// Banner component that displays habit count and limit for free users
/// Thin wrapper around ProUpgradeBanner for backward compatibility
struct HabitLimitBannerView: View {
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
