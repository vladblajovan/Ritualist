import SwiftUI
import RitualistCore
import UniformTypeIdentifiers

struct ICloudSyncSectionView: View {
    @Bindable var vm: SettingsViewModel
    @State private var showRestartAlert = false
    /// Tracks the initial sync preference when the view appeared (used to detect actual changes)
    @State private var initialSyncEnabled: Bool?

    var body: some View {
        Section {
            if vm.isPremiumUser {
                // MARK: - Premium User: Show Toggle

                Toggle("Enable iCloud Sync", isOn: Binding(
                    get: { vm.iCloudSyncEnabled },
                    set: { newValue in
                        vm.setICloudSyncEnabled(newValue)
                        // Only show alert if preference changed from the app launch state
                        if newValue != initialSyncEnabled {
                            showRestartAlert = true
                        }
                    }
                ))

                // Show helpful text based on current state
                if !vm.iCloudSyncEnabled {
                    Text("Enable to sync your habits across all your devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if vm.iCloudSyncEnabled {
                    syncStatusContent
                }
            } else if vm.iCloudStatus.canSync {
                // MARK: - Free User with iCloud Available (local-only, no sync)

                // Free users have local-only storage, so don't show sync status
                // which would be misleading since their data is NOT syncing
                Text("Your habits are stored locally on this device.")
                    .foregroundStyle(.secondary)

                // Upgrade prompt for free users
                Text("Upgrade to Pro to sync your habits across all your devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // MARK: - iCloud Not Available

                iCloudSetupPrompt
            }
        } header: {
            Text("iCloud Sync")
        } footer: {
            // Footer is no longer needed since we moved the explanation into the section content
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK") { }
        } message: {
            Text("Please restart the app for this change to take effect.")
        }
        .onAppear {
            // Capture initial sync preference on first appearance
            if initialSyncEnabled == nil {
                initialSyncEnabled = vm.iCloudSyncEnabled
            }
        }
    }

    // MARK: - Sync Status Content

    @ViewBuilder
    private var syncStatusContent: some View {
        // iCloud Account Status
        HStack {
            Label("Status", systemImage: "icloud")
                .foregroundStyle(.primary)

            Spacer()

            if vm.isCheckingCloudStatus {
                ProgressView()
                    .controlSize(.small)
            } else {
                statusIndicator
            }
        }

        // Last Synced Timestamp - only show when iCloud is available
        if let lastSync = vm.lastSyncDate {
            HStack {
                Label("Last Synced", systemImage: "clock")
                    .foregroundStyle(.primary)

                Spacer()

                Text(lastSync, format: .relative(presentation: .named))
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - iCloud Setup Prompt

    @ViewBuilder
    private var iCloudSetupPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.icloud")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Strings.ICloudSync.setupTitle)
                .font(.headline)

            Text(Strings.ICloudSync.setupDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(Strings.Settings.openSettings)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            statusIcon
            Text(vm.iCloudStatus.displayMessage)
                .font(.subheadline)
                .foregroundStyle(statusColor)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch vm.iCloudStatus {
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .notSignedIn:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .restricted:
            Image(systemName: "lock.fill")
                .foregroundStyle(.red)
        case .temporarilyUnavailable:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.yellow)
        case .timeout:
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(.orange)
        case .notConfigured:
            Image(systemName: "gearshape.fill")
                .foregroundStyle(.gray)
        case .unknown:
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.gray)
        }
    }

    private var statusColor: Color {
        switch vm.iCloudStatus {
        case .available:
            return .green
        case .notSignedIn:
            return .orange
        case .restricted:
            return .red
        case .temporarilyUnavailable:
            return .yellow
        case .timeout:
            return .orange
        case .notConfigured:
            return .gray
        case .unknown:
            return .secondary
        }
    }
}

#Preview {
    Form {
        ICloudSyncSectionView(vm: SettingsViewModel(
            loadProfile: MockLoadProfile(),
            saveProfile: MockSaveProfile(),
            requestNotificationPermission: MockRequestNotificationPermission(),
            checkNotificationStatus: MockCheckNotificationStatus(),
            requestLocationPermissions: MockRequestLocationPermissions(),
            getLocationAuthStatus: MockGetLocationAuthStatus(),
            clearPurchases: MockClearPurchases(),
            checkPremiumStatus: MockCheckPremiumStatus(),
            getCurrentSubscriptionPlan: MockGetCurrentSubscriptionPlan(),
            getSubscriptionExpiryDate: MockGetSubscriptionExpiryDate(),
            syncWithiCloud: MockSyncWithiCloud(),
            checkiCloudStatus: MockCheckiCloudStatus(),
            getLastSyncDate: MockGetLastSyncDate(),
            deleteiCloudData: MockDeleteiCloudData(),
            exportUserData: MockExportUserData(),
            importUserData: MockImportUserData(),
            getICloudSyncPreference: MockGetICloudSyncPreference(),
            setICloudSyncPreference: MockSetICloudSyncPreference()
        ))
    }
}

// MARK: - Preview Mocks

private struct MockLoadProfile: LoadProfileUseCase {
    func execute() async throws -> UserProfile {
        UserProfile()
    }
}

private struct MockSaveProfile: SaveProfileUseCase {
    func execute(_ profile: UserProfile) async throws {}
}

private struct MockRequestNotificationPermission: RequestNotificationPermissionUseCase {
    func execute() async throws -> Bool { true }
}

private struct MockCheckNotificationStatus: CheckNotificationStatusUseCase {
    func execute() async -> Bool { true }
}

private struct MockRequestLocationPermissions: RequestLocationPermissionsUseCase {
    func execute(requestAlways: Bool) async -> LocationPermissionResult {
        .granted(.authorizedWhenInUse)
    }
}

private struct MockGetLocationAuthStatus: GetLocationAuthStatusUseCase {
    func execute() async -> LocationAuthorizationStatus {
        .authorizedWhenInUse
    }
}

private struct MockClearPurchases: ClearPurchasesUseCase {
    func execute() {}
}

private struct MockCheckPremiumStatus: CheckPremiumStatusUseCase {
    func execute() async -> Bool { false }
}

private struct MockGetCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase {
    func execute() async -> SubscriptionPlan { .free }
}

private struct MockGetSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase {
    func execute() async -> Date? { nil }
}

private struct MockSyncWithiCloud: SyncWithiCloudUseCase {
    func execute() async throws {}
}

private struct MockCheckiCloudStatus: CheckiCloudStatusUseCase {
    func execute() async -> iCloudSyncStatus {
        .available
    }
}

private struct MockGetLastSyncDate: GetLastSyncDateUseCase {
    func execute() async -> Date? {
        Date().addingTimeInterval(-3600) // 1 hour ago
    }
}

private struct MockDeleteiCloudData: DeleteiCloudDataUseCase {
    func execute() async throws {}
}

private struct MockExportUserData: ExportUserDataUseCase {
    func execute() async throws -> String {
        """
        {
          "exportedAt": "2025-11-24T00:00:00Z",
          "profile": { "name": "Test User" },
          "habits": [],
          "categories": [],
          "habitLogs": [],
          "personalityData": { "currentProfile": null, "analysisHistory": [] }
        }
        """
    }
}

private struct MockImportUserData: ImportUserDataUseCase {
    func execute(jsonString: String) async throws {}
}

private struct MockGetICloudSyncPreference: GetICloudSyncPreferenceUseCase {
    func execute() -> Bool { true }
}

private struct MockSetICloudSyncPreference: SetICloudSyncPreferenceUseCase {
    func execute(_ enabled: Bool) {}
}

