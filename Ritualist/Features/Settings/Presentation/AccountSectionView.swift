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
        Section("Account") {
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
                .accessibilityLabel("Edit profile picture")
                .accessibilityHint("Double tap to change your avatar")

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

                    if vm.isUpdatingUser {
                        HStack {
                            ProgressView()
                                .scaleEffect(ScaleFactors.tiny)
                            Text("Updating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Gender Picker
            HStack {
                Label {
                    Picker("Gender", selection: $gender) {
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
                } icon: {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }

            // Age Group Picker
            HStack {
                Label {
                    Picker("Age Group", selection: $ageGroup) {
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
                } icon: {
                    Image(systemName: "number.circle")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
