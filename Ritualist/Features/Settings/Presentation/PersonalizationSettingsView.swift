//
//  PersonalizationSettingsView.swift
//  Ritualist
//
//  Dedicated settings page for user demographics (age group and gender).
//  This information helps personalize habit suggestions.
//

import SwiftUI
import RitualistCore

struct PersonalizationSettingsView: View {
    @Bindable var vm: SettingsViewModel
    @Binding var gender: UserGender
    @Binding var ageGroup: UserAgeGroup

    var body: some View {
        Form {
            Section {
                Text(Strings.Settings.personalizationExplanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section(Strings.Settings.demographics) {
                // Gender Picker
                Picker(Strings.Settings.gender, selection: $gender) {
                    ForEach(UserGender.allCases) { genderOption in
                        Text(genderOption.displayName).tag(genderOption)
                    }
                }
                .onChange(of: gender) { _, newValue in
                    HapticFeedbackService.shared.trigger(.selection)
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.updateGender(newValue)
                    }
                }

                // Age Group Picker
                Picker(Strings.Settings.ageGroup, selection: $ageGroup) {
                    ForEach(UserAgeGroup.allCases) { ageGroupOption in
                        Text(ageGroupOption.displayName).tag(ageGroupOption)
                    }
                }
                .onChange(of: ageGroup) { _, newValue in
                    HapticFeedbackService.shared.trigger(.selection)
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.updateAgeGroup(newValue)
                    }
                }
            }
        }
        .navigationTitle(Strings.Settings.personalization)
        .navigationBarTitleDisplayMode(.inline)
    }
}
