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
    @Injected(\.userDefaultsService) private var userDefaults
    @Injected(\.debugLogger) private var logger
    @Binding var showingResetOnboardingConfirmation: Bool
    @Binding var showingSimulateNewDeviceConfirmation: Bool
    @Binding var showingRestartRequiredAlert: Bool
    @Binding var restartInstructionMessage: String

    @State private var showingResetTipsConfirmation = false

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

            Text("Clears onboarding completion status. You'll need to manually restart the app to see the onboarding flow again.")
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

            Button(role: .destructive) {
                showingResetTipsConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)

                    Text("Reset Tips")

                    Spacer()
                }
            }
            .alert("Reset Tips?", isPresented: $showingResetTipsConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetTips()
                }
            } message: {
                Text("This will reset all TipKit tips so they can be shown again. Requires app restart.")
            }

            Text("Resets all TipKit tips so they can be shown again. Useful for testing the tip flow.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func resetTips() {
        userDefaults.set(true, forKey: "shouldResetTipsOnNextLaunch")
        logger.log("Tips reset scheduled - restart the app to see tips again", level: .info, category: .debug)

        restartInstructionMessage = "Tips reset scheduled. Please close and reopen the app to see the tips again."
        showingRestartRequiredAlert = true
    }
}
#endif
