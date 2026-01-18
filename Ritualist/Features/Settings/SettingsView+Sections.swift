//
//  SettingsView+Sections.swift
//  Ritualist
//
//  Extracted sections from SettingsFormView to reduce type body length.
//

import SwiftUI
import RitualistCore

// MARK: - Settings Section

struct SettingsSectionView: View {
    @Bindable var vm: SettingsViewModel
    @Binding var displayTimezoneMode: String
    @ObservedObject var hapticService: HapticFeedbackService

    var body: some View {
        Section(Strings.Settings.sectionSettings) {
            // Appearance
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                Label {
                    Text(Strings.Settings.sectionAppearance)
                } icon: {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Haptic Feedback (inline toggle)
            Toggle(isOn: $hapticService.isEnabled) {
                Label {
                    Text(Strings.Settings.hapticFeedback)
                } icon: {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }
            .onChange(of: hapticService.isEnabled) { _, newValue in
                if newValue {
                    HapticFeedbackService.shared.trigger(.medium)
                }
            }

            // Icon Visibility
            NavigationLink {
                IconVisibilitySettingsView()
            } label: {
                Label {
                    Text(Strings.Settings.sectionIconVisibility)
                } icon: {
                    Image(systemName: "eye")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }

            // Timezone
            NavigationLink {
                AdvancedSettingsView(
                    vm: vm,
                    displayTimezoneMode: $displayTimezoneMode
                )
            } label: {
                Label {
                    Text(Strings.Settings.timezoneSettings)
                } icon: {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }

            // iCloud Sync
            NavigationLink {
                ICloudSyncSettingsView(vm: vm)
            } label: {
                Label {
                    Text(Strings.ICloudSync.iCloud)
                } icon: {
                    Image(systemName: "icloud")
                        .font(.title2)
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - Support Section

struct SupportSectionView: View {
    var body: some View {
        Section(Strings.Settings.sectionSupport) {
            NavigationLink {
                UserGuideView()
            } label: {
                Label(Strings.UserGuide.title, systemImage: "book.fill")
            }

            Link(destination: AppURLs.supportEmail) {
                HStack {
                    Label(Strings.Settings.contactSupport, systemImage: "envelope")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: AppURLs.helpAndFAQ) {
                HStack {
                    Label(Strings.Settings.helpAndFAQ, systemImage: "questionmark.circle")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Legal Section

struct LegalSectionView: View {
    var body: some View {
        Section(Strings.Settings.sectionLegal) {
            Link(destination: AppURLs.privacyPolicy) {
                HStack {
                    Text(Strings.Settings.privacyPolicy)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: AppURLs.termsOfService) {
                HStack {
                    Text(Strings.Settings.termsOfService)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - About Section

struct AboutSectionView: View {
    @Binding var showBuildNumber: Bool

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        Section(Strings.Settings.sectionAbout) {
            // Version (tap to toggle build number)
            HStack {
                Text(showBuildNumber ? Strings.Settings.build : Strings.Settings.version)
                Spacer()
                Text(showBuildNumber ? buildNumber : appVersion)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showBuildNumber.toggle()
                }
            }

            #if DEBUG
            // Build number (only in debug/TestFlight builds)
            HStack {
                Text(Strings.Settings.build)
                Spacer()
                Text("(\(buildNumber))")
                    .foregroundColor(.secondary)
            }
            #endif

            // Acknowledgements (open source licenses)
            NavigationLink {
                AcknowledgementsView()
            } label: {
                Text(Strings.Settings.acknowledgements)
            }
        }
    }
}
