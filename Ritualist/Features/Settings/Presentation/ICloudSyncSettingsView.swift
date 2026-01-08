import SwiftUI
import RitualistCore

/// iCloud Sync settings page showing sync status, what syncs, and troubleshooting info
struct ICloudSyncSettingsView: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Form {
            // Intro Section
            IntroSectionView()

            // Sync Status Section
            SyncStatusSectionView(vm: vm)

            // What Syncs Section
            WhatSyncsSectionView()

            // Troubleshooting Section (only shown when there are issues)
            if !vm.iCloudStatus.canSync {
                TroubleshootingSectionView(status: vm.iCloudStatus)
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.refreshiCloudStatus()
        }
    }
}

// MARK: - Intro Section

private struct IntroSectionView: View {
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Your habits, categories, and progress sync automatically across all devices signed into the same iCloud account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Sync Status Section

private struct SyncStatusSectionView: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section {
            // Status Row
            HStack {
                Label("Status", systemImage: "icloud")
                    .foregroundStyle(.primary)

                Spacer()

                if vm.isCheckingCloudStatus {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    StatusIndicatorView(status: vm.iCloudStatus)
                }
            }

            // Last Synced Row
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
        } header: {
            Text("Sync Status")
        } footer: {
            if vm.iCloudStatus.canSync {
                Text("Changes sync automatically when you're connected to the internet.")
            }
        }
    }
}

// MARK: - Status Indicator

private struct StatusIndicatorView: View {
    let status: iCloudSyncStatus

    var body: some View {
        HStack(spacing: 4) {
            statusIcon
            Text(status.displayMessage)
                .font(.subheadline)
                .foregroundStyle(statusColor)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
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
        switch status {
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

// MARK: - What Syncs Section

private struct WhatSyncsSectionView: View {
    var body: some View {
        Section {
            SyncItemRow(
                title: String(localized: "Habits"),
                subtitle: String(localized: "All your habits and their settings")
            )
            SyncItemRow(
                title: String(localized: "Categories"),
                subtitle: String(localized: "Custom categories and colors")
            )
            SyncItemRow(
                title: String(localized: "Progress"),
                subtitle: String(localized: "Completions, streaks, and statistics")
            )
            SyncItemRow(
                title: String(localized: "Profile"),
                subtitle: String(localized: "Your name, avatar, and preferences")
            )
        } header: {
            Text("What Syncs")
        } footer: {
            Text("All data syncs automatically when changes are made. No manual sync required.")
        }
    }
}

private struct SyncItemRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "icloud.fill")
                .foregroundStyle(.blue)
                .font(.subheadline)
        }
    }
}

// MARK: - Troubleshooting Section

private struct TroubleshootingSectionView: View {
    let status: iCloudSyncStatus

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Problem description
                Text(problemDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Solution steps
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(solutionSteps, id: \.self) { step in
                        HStack(alignment: .top, spacing: Spacing.small) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(step)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.small)

            // Open Settings Button
            Button {
                openSystemSettings()
            } label: {
                HStack {
                    Label("Open Settings", systemImage: "gear")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Troubleshooting")
        }
    }

    private var problemDescription: String {
        switch status {
        case .notSignedIn:
            return String(localized: "You're not signed into iCloud. Sign in to sync your data across devices.")
        case .restricted:
            return String(localized: "iCloud access is restricted on this device, possibly by parental controls or device management.")
        case .temporarilyUnavailable:
            return String(localized: "iCloud is temporarily unavailable. This usually resolves itself shortly.")
        case .timeout:
            return String(localized: "Could not connect to iCloud. Check your internet connection.")
        case .notConfigured:
            return String(localized: "iCloud sync is not configured for this app.")
        case .unknown:
            return String(localized: "Could not determine iCloud status. Try again later.")
        case .available:
            return ""
        }
    }

    private var solutionSteps: [String] {
        switch status {
        case .notSignedIn:
            return [
                String(localized: "Open Settings on your device"),
                String(localized: "Tap your name at the top"),
                String(localized: "Sign in with your Apple ID"),
                String(localized: "Enable iCloud Drive")
            ]
        case .restricted:
            return [
                String(localized: "Check Screen Time or parental control settings"),
                String(localized: "Contact your device administrator"),
                String(localized: "Ensure iCloud is allowed for this app")
            ]
        case .temporarilyUnavailable, .timeout:
            return [
                String(localized: "Check your internet connection"),
                String(localized: "Try switching between Wi-Fi and cellular"),
                String(localized: "Wait a few minutes and try again")
            ]
        case .notConfigured, .unknown:
            return [
                String(localized: "Ensure you're signed into iCloud"),
                String(localized: "Check that iCloud Drive is enabled"),
                String(localized: "Try restarting the app")
            ]
        case .available:
            return []
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("Available") {
    NavigationStack {
        ICloudSyncSettingsView(vm: SettingsViewModel(
            loadProfile: PreviewMocks.LoadProfile(),
            saveProfile: PreviewMocks.SaveProfile(),
            permissionCoordinator: PreviewMocks.PermissionCoordinator(),
            checkNotificationStatus: PreviewMocks.CheckNotificationStatus(),
            getLocationAuthStatus: PreviewMocks.GetLocationAuthStatus(),
            clearPurchases: PreviewMocks.ClearPurchases(),
            checkPremiumStatus: PreviewMocks.CheckPremiumStatus(),
            getCurrentSubscriptionPlan: PreviewMocks.GetCurrentSubscriptionPlan(),
            getSubscriptionExpiryDate: PreviewMocks.GetSubscriptionExpiryDate(),
            syncWithiCloud: PreviewMocks.SyncWithiCloud(),
            checkiCloudStatus: PreviewMocks.CheckiCloudStatus(status: .available),
            getLastSyncDate: PreviewMocks.GetLastSyncDate(),
            deleteData: PreviewMocks.DeleteData(),
            exportUserData: PreviewMocks.ExportUserData(),
            importUserData: PreviewMocks.ImportUserData()
        ))
    }
}

#Preview("Not Signed In") {
    NavigationStack {
        ICloudSyncSettingsView(vm: SettingsViewModel(
            loadProfile: PreviewMocks.LoadProfile(),
            saveProfile: PreviewMocks.SaveProfile(),
            permissionCoordinator: PreviewMocks.PermissionCoordinator(),
            checkNotificationStatus: PreviewMocks.CheckNotificationStatus(),
            getLocationAuthStatus: PreviewMocks.GetLocationAuthStatus(),
            clearPurchases: PreviewMocks.ClearPurchases(),
            checkPremiumStatus: PreviewMocks.CheckPremiumStatus(),
            getCurrentSubscriptionPlan: PreviewMocks.GetCurrentSubscriptionPlan(),
            getSubscriptionExpiryDate: PreviewMocks.GetSubscriptionExpiryDate(),
            syncWithiCloud: PreviewMocks.SyncWithiCloud(),
            checkiCloudStatus: PreviewMocks.CheckiCloudStatus(status: .notSignedIn),
            getLastSyncDate: PreviewMocks.GetLastSyncDate(),
            deleteData: PreviewMocks.DeleteData(),
            exportUserData: PreviewMocks.ExportUserData(),
            importUserData: PreviewMocks.ImportUserData()
        ))
    }
}

// MARK: - Preview Mocks

private enum PreviewMocks {
    struct LoadProfile: LoadProfileUseCase {
        func execute() async throws -> UserProfile { UserProfile() }
    }

    struct SaveProfile: SaveProfileUseCase {
        func execute(_ profile: UserProfile) async throws {}
    }

    struct PermissionCoordinator: PermissionCoordinatorProtocol {
        func requestNotificationPermission() async -> NotificationPermissionOutcome { .success(true) }
        func requestLocationPermission(requestAlways: Bool) async -> LocationPermissionOutcome { .success(.authorizedWhenInUse) }
        func checkNotificationStatus() async -> Bool { true }
        func checkLocationStatus() async -> LocationAuthorizationStatus { .authorizedWhenInUse }
        func checkAllPermissions() async -> (notifications: Bool, location: LocationAuthorizationStatus) { (true, .authorizedWhenInUse) }
        func scheduleAllNotifications() async throws {}
        func restoreAllGeofences() async throws {}
    }

    struct CheckNotificationStatus: CheckNotificationStatusUseCase {
        func execute() async -> Bool { true }
    }

    struct GetLocationAuthStatus: GetLocationAuthStatusUseCase {
        func execute() async -> LocationAuthorizationStatus { .authorizedWhenInUse }
    }

    struct ClearPurchases: ClearPurchasesUseCase {
        func execute() async throws {}
    }

    struct CheckPremiumStatus: CheckPremiumStatusUseCase {
        func execute() async -> Bool { false }
    }

    struct GetCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase {
        func execute() async -> SubscriptionPlan { .free }
    }

    struct GetSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase {
        func execute() async -> Date? { nil }
    }

    struct SyncWithiCloud: SyncWithiCloudUseCase {
        func execute() async throws {}
    }

    struct CheckiCloudStatus: CheckiCloudStatusUseCase {
        var status: iCloudSyncStatus = .available
        func execute() async -> iCloudSyncStatus { status }
    }

    struct GetLastSyncDate: GetLastSyncDateUseCase {
        func execute() async -> Date? { Date().addingTimeInterval(-3600) }
    }

    struct DeleteData: DeleteDataUseCase {
        func execute() async throws {}
    }

    struct ExportUserData: ExportUserDataUseCase {
        func execute() async throws -> String { "{}" }
    }

    struct ImportUserData: ImportUserDataUseCase {
        func execute(jsonString: String) async throws -> ImportResult {
            ImportResult(hasLocationConfigurations: false, habitsImported: 0, habitLogsImported: 0, categoriesImported: 0)
        }
    }
}
