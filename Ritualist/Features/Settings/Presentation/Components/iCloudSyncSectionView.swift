import SwiftUI
import RitualistCore
import UniformTypeIdentifiers

struct ICloudSyncSectionView: View {
    @Bindable var vm: SettingsViewModel
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Section {
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

            // Last Synced Timestamp
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

            // Delete iCloud Data Button
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    if vm.isDeletingCloudData {
                        ProgressView()
                            .controlSize(.small)
                        Text("Deleting...")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Delete iCloud Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .disabled(!vm.iCloudStatus.canSync || vm.isDeletingCloudData)
            .opacity((!vm.iCloudStatus.canSync || vm.isDeletingCloudData) ? 0.5 : 1.0)

        } header: {
            Text("iCloud Sync")
        }
        .confirmationDialog(
            "Delete iCloud Data?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await vm.deleteCloudData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your profile from iCloud. Your local data will remain on this device.")
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
            importUserData: MockImportUserData()
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
        return """
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

