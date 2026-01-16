//
//  AppSettingsView.swift
//  Ritualist
//
//  App-level settings including haptic feedback, sounds, and other preferences.
//

import SwiftUI
import RitualistCore

/// App settings page for preferences like haptic feedback
struct AppSettingsView: View {
    @StateObject private var hapticService = HapticFeedbackService.shared

    var body: some View {
        Form {
            // Haptic Feedback Section
            Section {
                Toggle(isOn: $hapticService.isEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Settings.hapticFeedback)
                            Text(Strings.Settings.hapticFeedbackDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "waveform")
                            .foregroundColor(.purple)
                    }
                }
                .onChange(of: hapticService.isEnabled) { _, newValue in
                    // Provide haptic feedback when turning haptics back on
                    // so user gets immediate confirmation
                    if newValue {
                        HapticFeedbackService.shared.trigger(.medium)
                    }
                }
            } header: {
                Text(Strings.Settings.sectionFeedback)
            } footer: {
                Text(Strings.Settings.hapticFeedbackFooter)
            }
        }
        .navigationTitle(Strings.Settings.appSettings)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
    }
}
