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
    @State private var showingCancelConfirmation = false

    #if DEBUG
    @State private var showingDebugMenu = false
    #endif
    @Injected(\.paywallViewModel) var paywallViewModel
    
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

                    // Permissions Section (Notifications + Location)
                    PermissionsSectionView(vm: vm)

                    // iCloud Sync Section
                    ICloudSyncSectionView(vm: vm)

                    // Social Media Section
                    SocialMediaLinksView()

                    // Advanced Section
                    Section("Advanced") {
                        NavigationLink {
                            AdvancedSettingsView(
                                vm: vm,
                                displayTimezoneMode: $displayTimezoneMode
                            )
                        } label: {
                            HStack {
                                Label("Advanced Settings", systemImage: "gearshape.2")
                                Spacer()
                            }
                        }
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

                #if DEBUG
                .sheet(isPresented: $showingDebugMenu) {
                    NavigationStack {
                        DebugMenuView(vm: vm)
                    }
                }
                #endif
                .onAppear {
                    // Initialize local state and refresh all statuses
                    updateLocalState()
                    Task {
                        await vm.refreshNotificationStatus()
                        await vm.refreshLocationStatus()
                        await vm.refreshPremiumStatus()
                        await vm.refreshiCloudStatus()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
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
