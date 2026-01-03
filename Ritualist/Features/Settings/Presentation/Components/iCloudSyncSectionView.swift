import SwiftUI
import RitualistCore

struct ICloudSyncSectionView: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section {
            NavigationLink {
                ICloudSyncSettingsView(vm: vm)
            } label: {
                HStack {
                    Label("iCloud", systemImage: "icloud")
                        .foregroundStyle(.primary)

                    Spacer()

                    if vm.isLoading || vm.isCheckingCloudStatus {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        statusIndicator
                    }
                }
            }
        } header: {
            Text("Sync")
        } footer: {
            if vm.iCloudStatus.canSync {
                Text("Syncing across your devices.")
            } else {
                Text("Tap to see how to enable sync.")
            }
        }
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
    NavigationStack {
        Form {
            ICloudSyncSectionView(vm: SettingsViewModel(
                loadProfile: MockLoadProfile(),
                saveProfile: MockSaveProfile(),
                permissionCoordinator: MockPermissionCoordinator(),
                checkNotificationStatus: MockCheckNotificationStatus(),
                getLocationAuthStatus: MockGetLocationAuthStatus(),
                clearPurchases: MockClearPurchases(),
                checkPremiumStatus: MockCheckPremiumStatus(),
                getCurrentSubscriptionPlan: MockGetCurrentSubscriptionPlan(),
                getSubscriptionExpiryDate: MockGetSubscriptionExpiryDate(),
                syncWithiCloud: MockSyncWithiCloud(),
                checkiCloudStatus: MockCheckiCloudStatus(),
                getLastSyncDate: MockGetLastSyncDate(),
                deleteData: MockDeleteData(),
                exportUserData: MockExportUserData(),
                importUserData: MockImportUserData()
            ))
        }
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

private struct MockPermissionCoordinator: PermissionCoordinatorProtocol {
    func requestNotificationPermission() async -> NotificationPermissionOutcome { .success(true) }
    func requestLocationPermission(requestAlways: Bool) async -> LocationPermissionOutcome { .success(.authorizedWhenInUse) }
    func checkNotificationStatus() async -> Bool { true }
    func checkLocationStatus() async -> LocationAuthorizationStatus { .authorizedWhenInUse }
    func checkAllPermissions() async -> (notifications: Bool, location: LocationAuthorizationStatus) { (true, .authorizedWhenInUse) }
    func scheduleAllNotifications() async throws {}
    func restoreAllGeofences() async throws {}
}

private struct MockCheckNotificationStatus: CheckNotificationStatusUseCase {
    func execute() async -> Bool { true }
}

private struct MockGetLocationAuthStatus: GetLocationAuthStatusUseCase {
    func execute() async -> LocationAuthorizationStatus {
        .authorizedWhenInUse
    }
}

private struct MockClearPurchases: ClearPurchasesUseCase {
    func execute() async throws {}
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

private struct MockDeleteData: DeleteDataUseCase {
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
    func execute(jsonString: String) async throws -> ImportResult {
        ImportResult(hasLocationConfigurations: false, habitsImported: 0, habitLogsImported: 0, categoriesImported: 0)
    }
}
