import SwiftUI
import UIKit
import FactoryKit

public struct SettingsRoot: View {
    @Injected(\.settingsViewModel) var vm
    
    public init() {}
    
    public var body: some View {
        SettingsContentView(vm: vm)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await vm.load()
            }
    }
}

private struct SettingsContentView: View {
    @Bindable var vm: SettingsViewModel
    
    var body: some View {
        SettingsFormView(vm: vm)
    }
}

private struct SettingsFormView: View {
    @Bindable var vm: SettingsViewModel
    @FocusState private var isNameFieldFocused: Bool
    @State private var showingImagePicker = false
    @State private var selectedImageData: Data?
    @State private var paywallItem: PaywallItem?
    @Injected(\.paywallViewModel) var paywallViewModel
    
    // Local form state
    @State private var name = ""
    @State private var appearance = 0
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading settings...")
            } else if let error = vm.error {
                ErrorView(
                    title: "Failed to Load Settings",
                    message: error.localizedDescription
                ) {
                    await vm.retry()
                }
            } else {
                Form {
                    
                    // Account Section
                    Section("Account") {
                            // Avatar and Name row
                            HStack(spacing: Spacing.medium) {
                                AvatarView(
                                    name: displayName,
                                    imageData: vm.profile.avatarImageData,
                                    size: 60,
                                    showEditBadge: true
                                ) {
                                    showingImagePicker = true
                                }
                                
                                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                                    TextField(Strings.Form.name, text: $name)
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
                            // Subscription info
                            HStack {
                                Label("Subscription", systemImage: "crown")
                                Spacer()
                                Text(vm.isPremiumUser ? "Pro" : "Free")
                                    .foregroundColor(vm.isPremiumUser ? .orange : .secondary)
                                    .fontWeight(vm.isPremiumUser ? .medium : .regular)
                            }
                            
                            // Cancel subscription for premium users or Subscribe for free users
                            if vm.isPremiumUser {
                                Button {
                                    Task {
                                        await vm.cancelSubscription()
                                    }
                                } label: {
                                    HStack {
                                        if vm.isCancellingSubscription {
                                            ProgressView()
                                                .scaleEffect(ScaleFactors.smallMedium)
                                            Text("Cancelling...")
                                        } else {
                                            Label("Cancel Subscription", systemImage: "xmark.circle")
                                        }
                                        Spacer()
                                    }
                                    .foregroundColor(.orange)
                                }
                                .disabled(vm.isCancellingSubscription)
                            } else {
                                // Subscribe button for free users
                                Button {
                                    showPaywall()
                                } label: {
                                    HStack {
                                        Label("Subscribe to Pro", systemImage: "crown.fill")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                    }
                    
                    Section(Strings.Settings.profile) {
                        
                        HStack {
                            Picker(Strings.Settings.appearanceSetting, selection: $appearance) {
                                Text(Strings.Settings.followSystem).tag(0)
                                Text(Strings.Settings.light).tag(1)
                                Text(Strings.Settings.dark).tag(2)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    Section(Strings.Settings.notifications) {
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            HStack(spacing: Spacing.medium) {
                                Image(systemName: vm.hasNotificationPermission ? "bell.fill" : "bell.slash.fill")
                                    .foregroundColor(vm.hasNotificationPermission ? .green : .orange)
                                    .font(.title2)
                                    .frame(width: IconSize.large)
                                
                                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                                    Text(Strings.Settings.notificationPermission)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text(vm.hasNotificationPermission ? 
                                         Strings.Settings.notificationsEnabled :
                                         Strings.Settings.notificationsDisabled)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                    .frame(width: 24 + Spacing.medium)
                                
                                if !vm.hasNotificationPermission {
                                    Button(Strings.Settings.enable) {
                                        Task {
                                            await vm.requestNotifications()
                                        }
                                    }
                                    .disabled(vm.isRequestingNotifications)
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.regular)
                                    .overlay {
                                        if vm.isRequestingNotifications {
                                            ProgressView()
                                                .scaleEffect(ScaleFactors.smallMedium)
                                                .foregroundColor(.white)
                                        }
                                    }
                                } else {
                                    Button(Strings.Settings.openSettings) {
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                                }
                                Spacer()
                            }
                        }
                        .padding(.vertical, Spacing.small)
                    }
                }
                .refreshable {
                    await vm.load()
                    updateLocalState()
                }
                .onAppear {
                    updateLocalState()
                    Task {
                        await vm.refreshNotificationStatus()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                await saveChanges()
                            }
                        } label: {
                            if vm.isSaving {
                                ProgressView()
                                    .scaleEffect(ScaleFactors.smallMedium)
                            } else {
                                Text(Strings.Button.save)
                                    .fontWeight(hasChanges ? .semibold : .regular)
                            }
                        }
                        .disabled(!hasChanges || vm.isSaving)
                    }
                }
                .safeAreaInset(edge: .top) {
                    if vm.saveSuccess {
                        SettingsSavedConfirmationView(message: Strings.Settings.settingsSaved) {
                            vm.clearSaveSuccess()
                        }
                        .padding(.top, Spacing.small)
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    AvatarImagePicker(
                        name: displayName,
                        currentImageData: vm.profile.avatarImageData,
                        selectedImageData: $selectedImageData
                    ) { newImageData in
                        vm.profile.avatarImageData = newImageData
                        Task {
                            _ = await vm.save()
                        }
                        selectedImageData = nil
                    } onDismiss: {
                        selectedImageData = nil
                        showingImagePicker = false
                    }
                }
                .sheet(item: $paywallItem) { item in
                    PaywallView(vm: item.viewModel)
                }
                .onAppear {
                    // Refresh premium status when settings page appears
                    vm.refreshPremiumStatus()
                    updateLocalState()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showPaywall() {
        Task { @MainActor in
            await paywallViewModel.load()
            paywallItem = PaywallItem(viewModel: paywallViewModel)
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayName: String {
        vm.profile.name
    }
    
    private var hasChanges: Bool {
        name != vm.profile.name ||
               appearance != vm.profile.appearance
    }
    
    private func updateLocalState() {
        name = vm.profile.name
        appearance = vm.profile.appearance
    }
    
    private func updateUserName() async {
        // Update both profile name and user service
        await vm.updateUserName(name)
        vm.profile.name = name
        _ = await vm.save()
    }
    
    private func saveChanges() async {
        // Update profile settings
        vm.profile.name = name
        vm.profile.appearance = appearance
        _ = await vm.save()
        
        // Also update the user service name
        await vm.updateUserName(name)
        
        // TODO: Update app appearance via SettingsViewModel instead of direct access
        // The ViewModel should handle appearance updates internally
        // await MainActor.run {
        //     appContainer.appearanceManager.updateFromProfile(vm.profile)
        // }
        
        // Update local state to reflect saved values
        updateLocalState()
    }
    
    
    private func appearanceName(_ appearance: Int) -> String {
        switch appearance {
        case 0: return "Follow System"
        case 1: return "Light"
        case 2: return "Dark"
        default: return "Unknown"
        }
    }
}

private struct SettingsSavedConfirmationView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, Spacing.large)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: message)
        .task {
            // Auto-dismiss after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            onDismiss()
        }
    }
}

#Preview {
    SettingsRoot()
}
