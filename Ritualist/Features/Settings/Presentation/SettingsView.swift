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
    @State private var showingCancelConfirmation = false

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
                    AccountSectionView(
                        vm: vm,
                        name: $name,
                        appearance: $appearance,
                        displayTimezoneMode: $displayTimezoneMode,
                        isNameFieldFocused: $isNameFieldFocused,
                        showingImagePicker: $showingImagePicker,
                        showingCancelConfirmation: $showingCancelConfirmation,
                        showPaywall: showPaywall,
                        updateUserName: updateUserName
                    )
                    
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
                                .accessibilityLabel("Request notification permission")
                                .accessibilityHint("Tap to enable notifications")
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
                                .accessibilityLabel("Open notification settings")
                                .accessibilityHint("Opens iOS Settings app")
                            }
                        }
                        .padding(.vertical, Spacing.small)
                    }

                    // Location Permissions Section
                    Section("Location") {
                        HStack(spacing: Spacing.medium) {
                            Image(systemName: vm.locationAuthStatus.canMonitorGeofences ? "location.fill" : "location.slash.fill")
                                .foregroundColor(vm.locationAuthStatus.canMonitorGeofences ? .green : .orange)
                                .font(.title2)
                                .frame(width: IconSize.large)

                            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                                Text("Location Permission")
                                    .font(.headline)
                                    .fontWeight(.medium)

                                Text(vm.locationAuthStatus.displayText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            // Action button on the right
                            if vm.isRequestingLocationPermission {
                                ProgressView()
                                    .scaleEffect(ScaleFactors.smallMedium)
                            } else if !vm.locationAuthStatus.canMonitorGeofences {
                                Button {
                                    Task {
                                        await vm.requestLocationPermission()
                                    }
                                } label: {
                                    Image(systemName: "location.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                .accessibilityLabel("Request location permission")
                                .accessibilityHint("Tap to enable location services")
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
                                .accessibilityLabel("Open location settings")
                                .accessibilityHint("Opens iOS Settings app")
                            }
                        }
                        .padding(.vertical, Spacing.small)
                    }

                    // Social Media Section
                    SocialMediaLinksView()

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
                        await vm.refreshLocationStatus()
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
