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
            .onAppear {
                vm.setViewVisible(true)
            }
            .onDisappear {
                vm.setViewVisible(false)
                vm.markViewDisappeared()
            }
            .onChange(of: vm.isViewVisible) { wasVisible, isVisible in
                // When view becomes visible (tab switch), reload to pick up changes from other tabs
                // Skip on initial appear - the .task modifier handles initial load.
                if !wasVisible && isVisible && vm.isReturningFromTabSwitch {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        logger.log("Tab switch detected: Reloading settings data", level: .debug, category: .ui)
                        await vm.reload()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                // Auto-refresh when iCloud syncs new data from another device
                // This updates profile name, avatar, appearance, and timezone settings
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    logger.log(
                        "☁️ iCloud sync detected - refreshing Settings",
                        level: .info,
                        category: .system
                    )
                    await vm.reload()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .premiumStatusDidChange)) { _ in
                // Refresh subscription status when purchase completes
                // This updates the subscription section immediately after paywall dismisses
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    logger.log(
                        "💳 Premium status changed - refreshing subscription status",
                        level: .info,
                        category: .subscription
                    )
                    await vm.refreshSubscriptionStatus()
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
    @Injected(\.debugLogger) private var logger
    @StateObject private var hapticService = HapticFeedbackService.shared
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
    @State private var showBuildNumber = false

    var body: some View {
        Group {
            if let error = vm.error {
                ErrorView(
                    title: Strings.Settings.failedToLoad,
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

                    // Subscription Section
                    SubscriptionManagementSectionView(vm: vm)

                    #if DEBUG
                    // Debug Section
                    Section(Strings.Settings.sectionDebug) {
                        GenericRowView.settingsRow(
                            title: Strings.Settings.debugMenu,
                            subtitle: Strings.Settings.debugMenuSubtitle,
                            icon: "wrench.and.screwdriver",
                            iconColor: .red
                        ) {
                            showingDebugMenu = true
                        }
                    }
                    #endif

                    // Settings Section
                    SettingsSectionView(
                        vm: vm,
                        displayTimezoneMode: $displayTimezoneMode,
                        hapticService: hapticService
                    )

                    // Permissions Section (Notifications + Location)
                    PermissionsSectionView(vm: vm)

                    // Data Section (Export/Import/Delete)
                    DataManagementSectionView(vm: vm) { result in
                        vm.showDeleteResultToast(result)
                    }

                    // Support Section
                    SupportSectionView()

                    // Legal Section
                    LegalSectionView()

                    // Connect With Us Section
                    SocialMediaLinksView()

                    // About Section
                    AboutSectionView(showBuildNumber: $showBuildNumber)
                }
                .contentMargins(.top, 0, for: .scrollContent)
                .refreshable {
                        await vm.reload()
                        updateLocalState()
                    }
                    .sheet(isPresented: $showingImagePicker) {
                    AvatarImagePicker(
                        name: displayName,
                        currentImageData: vm.profile.avatarImageData,
                        selectedImageData: $selectedImageData
                    ) { newImageData in
                        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                        Task { @MainActor in
                            await vm.updateAvatar(newImageData)
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
                            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                await vm.refreshSubscriptionStatus()
                                await vm.reload()
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
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in await vm.refreshNotificationStatus() }
                    Task { @MainActor in await vm.refreshLocationStatus() }
                    Task { @MainActor in await vm.refreshPremiumStatus() }
                    Task { @MainActor in await vm.refreshiCloudStatus() }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Refresh iCloud status when app becomes active (handles connectivity changes)
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.refreshiCloudStatus()
                    }
                }
                .onChange(of: vm.profile) { _, _ in
                    // Sync local state when profile changes (e.g., after delete all data)
                    updateLocalState()
                }
            } // else
        } // Group
        .navigationBarTitleDisplayMode(.inline)
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
        if let genderRaw = vm.profile.gender {
            if let parsedGender = UserGender(rawValue: genderRaw) {
                gender = parsedGender
            } else {
                logger.log(
                    "Failed to parse gender from profile",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["raw_value": genderRaw]
                )
                gender = .preferNotToSay
            }
        } else {
            gender = .preferNotToSay
        }
        if let ageRaw = vm.profile.ageGroup {
            if let parsedAgeGroup = UserAgeGroup(rawValue: ageRaw) {
                ageGroup = parsedAgeGroup
            } else {
                logger.log(
                    "Failed to parse age group from profile",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["raw_value": ageRaw]
                )
                ageGroup = .preferNotToSay
            }
        } else {
            ageGroup = .preferNotToSay
        }
    }

    private func updateUserName() async {
        await vm.updateName(name)
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
