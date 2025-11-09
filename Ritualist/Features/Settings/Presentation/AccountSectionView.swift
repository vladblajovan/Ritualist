import SwiftUI
import RitualistCore

/// Account section for Settings page including profile, appearance, and time display
struct AccountSectionView: View {
    @Bindable var vm: SettingsViewModel
    @Binding var name: String
    @Binding var appearance: Int
    @Binding var displayTimezoneMode: String
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

            // Appearance Picker
            HStack {
                Label {
                    Picker(Strings.Settings.appearanceSetting, selection: $appearance) {
                        Text(Strings.Settings.followSystem).tag(0)
                        Text(Strings.Settings.light).tag(1)
                        Text(Strings.Settings.dark).tag(2)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: appearance) { _, newValue in
                        Task {
                            // Auto-save appearance changes
                            vm.profile.appearance = newValue
                            _ = await vm.save()
                            await vm.updateAppearance(newValue)
                        }
                    }
                } icon: {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
