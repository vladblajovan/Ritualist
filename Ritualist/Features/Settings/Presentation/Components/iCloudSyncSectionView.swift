import SwiftUI
import RitualistCore

struct ICloudSyncSectionView: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section {
            // iCloud Account Status
            HStack {
                Label("iCloud Status", systemImage: "icloud")
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
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(lastSync, format: .relative(presentation: .named))
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }

            // Sync Now Button
            Button {
                Task {
                    await vm.syncNow()
                }
            } label: {
                HStack {
                    if vm.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                        Text("Syncing...")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .disabled(!vm.iCloudStatus.canSync || vm.isSyncing)

        } header: {
            Text("iCloud Sync")
        } footer: {
            footerText
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

    // MARK: - Footer Text

    @ViewBuilder
    private var footerText: some View {
        switch vm.iCloudStatus {
        case .available:
            Text("Your profile syncs automatically across all your devices using iCloud.")
        case .notSignedIn:
            Text("Sign in to iCloud in Settings to enable automatic sync across your devices.")
        case .restricted:
            Text("iCloud is restricted. Check Screen Time or parental controls in Settings.")
        case .temporarilyUnavailable:
            Text("iCloud is temporarily unavailable. Your profile will sync when iCloud is accessible.")
        case .unknown:
            Text("Checking iCloud status...")
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
            updateUserSubscription: MockUpdateUserSubscription(),
            syncWithiCloud: MockSyncWithiCloud(),
            checkiCloudStatus: MockCheckiCloudStatus(),
            getLastSyncDate: MockGetLastSyncDate(),
            updateLastSyncDate: MockUpdateLastSyncDate()
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

private struct MockUpdateUserSubscription: UpdateUserSubscriptionUseCase {
    func execute(plan: SubscriptionPlan, expiryDate: Date?) async throws {}
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

private struct MockUpdateLastSyncDate: UpdateLastSyncDateUseCase {
    func execute(_ date: Date) async {}
}
