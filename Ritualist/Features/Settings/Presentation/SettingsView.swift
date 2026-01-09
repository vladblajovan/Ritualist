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
                    Task {
                        logger.log("Tab switch detected: Reloading settings data", level: .debug, category: .ui)
                        await vm.reload()
                    }
                }
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
                    await vm.reload()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .premiumStatusDidChange)) { _ in
                // Refresh subscription status when purchase completes
                // This updates the subscription section immediately after paywall dismisses
                Task {
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

    // Version information
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

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

                    // Appearance Section
                    Section(Strings.Settings.sectionAppearance) {
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

                    // Timezone Section
                    Section(Strings.Settings.sectionTimezone) {
                        NavigationLink {
                            AdvancedSettingsView(
                                vm: vm,
                                displayTimezoneMode: $displayTimezoneMode
                            )
                        } label: {
                            HStack {
                                Label(Strings.Settings.timezoneSettings, systemImage: "clock.badge.questionmark")
                                Spacer()
                            }
                        }
                    }

                    // Subscription Section
                    SubscriptionManagementSectionView(vm: vm)

                    // iCloud Sync Section
                    ICloudSyncSectionView(vm: vm)

                    // Permissions Section (Notifications + Location)
                    PermissionsSectionView(vm: vm)

                    // Data Management Section (Export/Import/Delete)
                    DataManagementSectionView(vm: vm) { result in
                        vm.showDeleteResultToast(result)
                    }

                    // Social Media Section
                    SocialMediaLinksView()

                    // Support Section
                    Section(Strings.Settings.sectionSupport) {
                        Link(destination: AppURLs.supportEmail) {
                            HStack {
                                Label(Strings.Settings.contactSupport, systemImage: "envelope")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Link(destination: AppURLs.helpAndFAQ) {
                            HStack {
                                Label(Strings.Settings.helpAndFAQ, systemImage: "questionmark.circle")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Legal Section
                    Section(Strings.Settings.sectionLegal) {
                        Link(destination: AppURLs.privacyPolicy) {
                            HStack {
                                Text(Strings.Settings.privacyPolicy)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Link(destination: AppURLs.termsOfService) {
                            HStack {
                                Text(Strings.Settings.termsOfService)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // About Section
                    Section(Strings.Settings.sectionAbout) {
                        // Version (always visible)
                        HStack {
                            Text(Strings.Settings.version)
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.secondary)
                        }

                        #if DEBUG
                        // Build number (only in debug/TestFlight builds)
                        HStack {
                            Text(Strings.Settings.build)
                            Spacer()
                            Text("(\(buildNumber))")
                                .foregroundColor(.secondary)
                        }
                        #endif

                        // Acknowledgements (open source licenses)
                        NavigationLink {
                            AcknowledgementsView()
                        } label: {
                            Text(Strings.Settings.acknowledgements)
                        }
                    }
                }
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
                        Task {
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
                            Task {
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
                .onChange(of: vm.profile) { _, _ in
                    // Sync local state when profile changes (e.g., after delete all data)
                    updateLocalState()
                }
            } // else
        } // Group
        .navigationTitle(Strings.Settings.title)
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
