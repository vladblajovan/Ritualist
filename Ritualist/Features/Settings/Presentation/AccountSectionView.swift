import SwiftUI
import RitualistCore

/// Account section for Settings page including profile, appearance, and time display
struct AccountSectionView: View {
    @Bindable var vm: SettingsViewModel
    @Binding var name: String
    @Binding var appearance: Int
    @Binding var displayTimezoneMode: String
    @Binding var gender: UserGender
    @Binding var ageGroup: UserAgeGroup
    @FocusState.Binding var isNameFieldFocused: Bool
    @Binding var showingImagePicker: Bool
    let updateUserName: () async -> Void

    var body: some View {
        Section {
            // Avatar and Name row
            HStack(spacing: Spacing.medium) {
                AvatarView(
                    name: vm.profile.name,
                    imageData: vm.profile.avatarImageData,
                    size: 60,
                    showEditBadge: true
                ) {
                    showingImagePicker = true
                }
                .accessibilityLabel(Strings.Settings.editProfilePicture)
                .accessibilityHint(Strings.Settings.changeAvatarHint)

                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    TextField(Strings.Form.name, text: $name)
                        .textFieldStyle(.plain)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isNameFieldFocused)
                        .onSubmit {
                            isNameFieldFocused = false
                            Task {
                                await updateUserName()
                            }
                        }
                        .accessibilityLabel(Strings.Settings.yourName)
                        .accessibilityHint(Strings.Settings.enterDisplayName)

                    if vm.isUpdatingUser {
                        HStack {
                            ProgressView()
                                .scaleEffect(ScaleFactors.tiny)
                            Text(Strings.Settings.updating)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Gender Picker
            HStack {
                Label {
                    Picker(Strings.Settings.gender, selection: $gender) {
                        ForEach(UserGender.allCases) { genderOption in
                            Text(genderOption.displayName).tag(genderOption)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: gender) { _, newValue in
                        Task {
                            await vm.updateGender(newValue)
                        }
                    }
                    .accessibilityLabel(Strings.Settings.gender)
                    .accessibilityHint(Strings.Settings.genderHint)
                } icon: {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }

            // Age Group Picker
            HStack {
                Label {
                    Picker(Strings.Settings.ageGroup, selection: $ageGroup) {
                        ForEach(UserAgeGroup.allCases) { ageGroupOption in
                            Text(ageGroupOption.displayName).tag(ageGroupOption)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: ageGroup) { _, newValue in
                        Task {
                            await vm.updateAgeGroup(newValue)
                        }
                    }
                    .accessibilityLabel(Strings.Settings.ageGroup)
                    .accessibilityHint(Strings.Settings.ageGroupHint)
                } icon: {
                    Image(systemName: "number.circle")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
