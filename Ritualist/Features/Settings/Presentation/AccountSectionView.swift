import SwiftUI
import RitualistCore

/// Account section for Settings page including profile and personalization link
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

    /// Whether user has chosen "prefer not to say" for either demographic
    private var hasMissingDemographics: Bool {
        gender == .preferNotToSay || ageGroup == .preferNotToSay
    }

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

            // Personalization row - show subtitle hint when demographics are missing
            NavigationLink {
                PersonalizationSettingsView(
                    vm: vm,
                    gender: $gender,
                    ageGroup: $ageGroup
                )
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                        Text(Strings.Settings.personalization)

                        if hasMissingDemographics {
                            Text(Strings.Settings.personalizationTip)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "person.text.rectangle")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }
        }
    }
}
