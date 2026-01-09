//
//  DebugMenuOnboardingSection.swift
//  Ritualist
//

import SwiftUI
import RitualistCore
import FactoryKit

#if DEBUG
struct DebugMenuOnboardingSection: View {
    @Bindable var vm: SettingsViewModel
    @Binding var showingResetOnboardingConfirmation: Bool
    @Binding var showingSimulateNewDeviceConfirmation: Bool

    var body: some View {
        Section("Onboarding Management") {
            Button(role: .destructive) {
                showingResetOnboardingConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.purple)

                    Text("Reset Onboarding")

                    Spacer()
                }
            }

            Text("Clears onboarding completion status and resets tips. Restart the app to see the onboarding flow and tips again.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(role: .destructive) {
                showingSimulateNewDeviceConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "iphone.and.arrow.forward")
                        .foregroundColor(.blue)

                    Text("Simulate New Device")

                    Spacer()
                }
            }

            Text("Simulates a returning user on a new device: keeps iCloud onboarding flag set but clears local device flags. Useful for testing returning user flow without deleting the app.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif
