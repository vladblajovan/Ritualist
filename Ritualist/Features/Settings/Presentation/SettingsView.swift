import SwiftUI
import UIKit
import FactoryKit
import RitualistCore

public struct SettingsRoot: View {
    @Injected(\.settingsViewModel) var vm
    
    public init() {}
    
    public var body: some View {
        SettingsContentView(vm: vm)
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
    @State private var showingCategoryManagement = false
    
    #if DEBUG
    @State private var showingDebugMenu = false
    #endif
    @Injected(\.paywallViewModel) var paywallViewModel
    @Injected(\.categoryManagementViewModel) var categoryManagementVM
    
    // Local form state
    @State private var name = ""
    @State private var appearance = 0
    @State private var displayTimezoneMode = "original"
    
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
                            .onChange(of: appearance) { _, newValue in
                                Task {
                                    // Auto-save appearance changes
                                    vm.profile.appearance = newValue
                                    _ = await vm.save()
                                    await vm.updateAppearance(newValue)
                                }
                            }
                        }
                    }
                    
                    Section("Time Display") {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Picker("Display Mode", selection: $displayTimezoneMode) {
                                Text("Original Time").tag("original")
                                Text("Current Time").tag("current")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: displayTimezoneMode) { _, newValue in
                                Task {
                                    vm.profile.displayTimezoneMode = newValue
                                    _ = await vm.save()
                                }
                            }

                            Text(timezoneExplanationText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, Spacing.small)
                    }
                    
                    Section("Data Management") {
                        GenericRowView.settingsRow(
                            title: "Manage Categories",
                            subtitle: "Add, edit, or delete habit categories",
                            icon: "folder.badge.gearshape",
                            iconColor: .orange
                        ) {
                            showingCategoryManagement = true
                        }
                    }
                    
                    Section("Personality Insights") {
                        PersonalityInsightsSettingsRow()
                    }

                    Section(Strings.Settings.notifications) {
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
                            
                            // Action button on the right
                            if vm.isRequestingNotifications {
                                ProgressView()
                                    .scaleEffect(ScaleFactors.smallMedium)
                            } else if !vm.hasNotificationPermission {
                                Button {
                                    Task {
                                        await vm.requestNotifications()
                                    }
                                } label: {
                                    Image(systemName: "bell.badge")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Button {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.small)
                    }

                    #if DEBUG
                    Section("Debug") {
                        GenericRowView.settingsRow(
                            title: "Debug Menu",
                            subtitle: "Development tools and database management",
                            icon: "wrench.and.screwdriver",
                            iconColor: .red
                        ) {
                            showingDebugMenu = true
                        }
                    }
                    #endif
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
                .sheet(isPresented: $showingCategoryManagement) {
                    NavigationStack {
                        CategoryManagementView(vm: categoryManagementVM)
                    }
                }
                
                #if DEBUG
                .sheet(isPresented: $showingDebugMenu) {
                    NavigationStack {
                        DebugMenuView(vm: vm)
                    }
                }
                #endif
                .onAppear {
                    // Refresh premium status when settings page appears
                    Task {
                        await vm.refreshPremiumStatus()
                    }
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
    
    private var timezoneExplanationText: String {
        switch displayTimezoneMode {
        case "original":
            return "Show times as they were originally experienced (preserves timezone context)"
        case "current":
            return "Show all times in your current device timezone"
        default:
            return "Choose how to display timestamps in the app"
        }
    }

    private func updateLocalState() {
        name = vm.profile.name
        appearance = vm.profile.appearance
        displayTimezoneMode = vm.profile.displayTimezoneMode
    }
    
    private func updateUserName() async {
        // Update both profile name and user service
        await vm.updateUserName(name)
        vm.profile.name = name
        _ = await vm.save()
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


#Preview {
    SettingsRoot()
}
