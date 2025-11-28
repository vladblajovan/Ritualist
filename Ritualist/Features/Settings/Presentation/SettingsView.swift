import SwiftUI
import UIKit
import FactoryKit
import RitualistCore

public struct SettingsRoot: View {
    @Injected(\.settingsViewModel) var vm
    @Injected(\.debugLogger) private var logger

    public init() {}

    public var body: some View {
        SettingsContentView(vm: vm)
            .task {
                await vm.load()
            }
            .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                // Auto-refresh when iCloud syncs new data from another device
                // This updates profile name, avatar, appearance, and timezone settings
                Task {
                    logger.log(
                        "☁️ iCloud sync detected - refreshing Settings",
                        level: .info,
                        category: .system
                    )
                    await vm.load()
                }
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

    #if DEBUG
    @State private var showingDebugMenu = false
    #endif

    // Local form state
    @State private var name = ""
    @State private var appearance = 0
    @State private var displayTimezoneMode = "original"
    @State private var gender: UserGender = .preferNotToSay
    @State private var ageGroup: UserAgeGroup = .preferNotToSay

    // Toast state
    @State private var activeToast: SettingsToast?

    private enum SettingsToast {
        case avatarUpdated
        case avatarRemoved
        case nameUpdated
    }

    // Version information
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

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
                        gender: $gender,
                        ageGroup: $ageGroup,
                        isNameFieldFocused: $isNameFieldFocused,
                        showingImagePicker: $showingImagePicker,
                        updateUserName: updateUserName
                    )

                    #if DEBUG
                    // Debug Section (positioned after Account for easy access)
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

                    // Subscription Section
                    SubscriptionManagementSectionView(vm: vm)

                    // Permissions Section (Notifications + Location)
                    PermissionsSectionView(vm: vm)

                    // iCloud Sync Section
                    ICloudSyncSectionView(vm: vm)

                    // Data Management Section (Export/Import)
                    DataManagementSectionView(vm: vm)

                    // Advanced Section
                    Section("Advanced") {
                        NavigationLink {
                            AdvancedSettingsView(
                                vm: vm,
                                displayTimezoneMode: $displayTimezoneMode,
                                appearance: $appearance
                            )
                        } label: {
                            HStack {
                                Label("Advanced Settings", systemImage: "gearshape.2")
                                Spacer()
                            }
                        }
                    }

                    // Social Media Section
                    SocialMediaLinksView()

                    // About Section
                    Section("About") {
                        // Version (always visible)
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.secondary)
                        }

                        #if DEBUG
                        // Build number (only in debug/TestFlight builds)
                        HStack {
                            Text("Build")
                            Spacer()
                            Text("(\(buildNumber))")
                                .foregroundColor(.secondary)
                        }
                        #endif
                    }
                }
                .refreshable {
                    await vm.load()
                    updateLocalState()
                }
                .sheet(isPresented: $showingImagePicker) {
                    AvatarImagePicker(
                        name: displayName,
                        currentImageData: vm.profile.avatarImageData,
                        selectedImageData: $selectedImageData
                    ) { newImageData in
                        let isRemoving = newImageData == nil && vm.profile.avatarImageData != nil
                        vm.profile.avatarImageData = newImageData
                        Task {
                            let success = await vm.save()
                            if success {
                                await MainActor.run {
                                    activeToast = isRemoving ? .avatarRemoved : .avatarUpdated
                                }
                            }
                        }
                        selectedImageData = nil
                    } onDismiss: {
                        selectedImageData = nil
                        showingImagePicker = false
                    }
                }
                .sheet(item: $vm.paywallItem) { item in
                    PaywallView(vm: item.viewModel)
                        .onDisappear {
                            // Refresh subscription status after paywall dismissal
                            Task {
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                await vm.refreshSubscriptionStatus()
                                await vm.load()
                            }
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
                    // Initialize local state
                    updateLocalState()
                    // Run all refresh operations in parallel for faster startup
                    Task { await vm.refreshNotificationStatus() }
                    Task { await vm.refreshLocationStatus() }
                    Task { await vm.refreshPremiumStatus() }
                    Task { await vm.refreshiCloudStatus() }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Refresh iCloud status when app becomes active (handles connectivity changes)
                    Task {
                        await vm.refreshiCloudStatus()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .top) {
            if let toast = activeToast {
                toastView(for: toast)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeToast != nil)
    }

    @ViewBuilder
    private func toastView(for toast: SettingsToast) -> some View {
        switch toast {
        case .avatarUpdated:
            ToastView(
                message: "Profile photo updated",
                icon: "person.crop.circle.fill.badge.checkmark",
                style: .success
            ) { activeToast = nil }
        case .avatarRemoved:
            ToastView(
                message: "Profile photo removed",
                icon: "person.crop.circle.badge.minus",
                style: .info
            ) { activeToast = nil }
        case .nameUpdated:
            ToastView(
                message: "Name updated",
                icon: "person.fill.checkmark",
                style: .success
            ) { activeToast = nil }
        }
    }

    // MARK: - Computed Properties
    
    private var displayName: String {
        vm.profile.name
    }

    private func updateLocalState() {
        name = vm.profile.name
        appearance = vm.profile.appearance
        displayTimezoneMode = vm.profile.displayTimezoneMode.toLegacyString()
        // Load gender/ageGroup from profile (converting from raw string values)
        if let genderRaw = vm.profile.gender, let g = UserGender(rawValue: genderRaw) {
            gender = g
        } else {
            gender = .preferNotToSay
        }
        if let ageRaw = vm.profile.ageGroup, let a = UserAgeGroup(rawValue: ageRaw) {
            ageGroup = a
        } else {
            ageGroup = .preferNotToSay
        }
    }
    
    private func updateUserName() async {
        // Update both profile name and user service
        await vm.updateUserName(name)
        vm.profile.name = name
        let success = await vm.save()
        if success {
            activeToast = .nameUpdated
        }
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
