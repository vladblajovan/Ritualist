import SwiftUI
import StoreKit
import RitualistCore

struct SubscriptionManagementSectionView: View {
    @Bindable var vm: SettingsViewModel
    @State private var isRestoringPurchases = false
    @State private var showingRestoreAlert = false
    @State private var restoreAlertMessage = ""

    var body: some View {
        Section {
            // AllFeatures Mode Indicator (TestFlight/Debug builds)
            #if ALL_FEATURES_ENABLED
            HStack {
                Label(Strings.Subscription.mode, systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text(Strings.Subscription.allFeaturesUnlocked)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
            }
            #else
            // Subscription Status Row (Production)
            Label {
                Text(vm.isOnTrial ? Strings.Subscription.trial : vm.subscriptionPlan.displayName)
            } icon: {
                Image(systemName: subscriptionIconConfig.name)
                    .foregroundStyle(subscriptionIconConfig.style)
            }
            #endif

            #if !ALL_FEATURES_ENABLED
            // Upgrade Banner (for free users only)
            if vm.subscriptionPlan == .free {
                UpgradeBannerView(onUpgradeTap: showPaywall)
            }

            // Expiry Date Row (for subscriptions)
            // Shows "Billing starts" for trial users, "Renews" for active subscribers
            if let expiryDate = vm.subscriptionExpiryDate {
                HStack {
                    Label(
                        vm.isOnTrial ? Strings.Subscription.billingStarts : Strings.Subscription.renews,
                        systemImage: "calendar"
                    )
                    .foregroundStyle(.secondary)

                    Spacer()

                    Text(expiryDate, format: .dateTime.month().day().year())
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }

            // Restore Purchases Button (for free users only - in case they have a purchase not synced)
            if vm.subscriptionPlan == .free {
                Button {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await restorePurchases()
                    }
                } label: {
                    HStack {
                        if isRestoringPurchases {
                            ProgressView()
                                .controlSize(.small)
                            Text(Strings.Subscription.restoring)
                                .foregroundStyle(.secondary)
                        } else {
                            Label(Strings.Subscription.restorePurchases, systemImage: "arrow.clockwise")
                        }
                    }
                }
                .disabled(isRestoringPurchases)
            }

            // Billing Issue Banner (for premium users with payment problems)
            // Shows when user is in billing grace period or billing retry
            if vm.hasBillingIssue && vm.subscriptionPlan != .free {
                BillingIssueBannerView(onResolveTap: openSubscriptionManagement)
            }

            // Manage Subscription Button (for all premium users)
            if vm.subscriptionPlan == .weekly || vm.subscriptionPlan == .monthly || vm.subscriptionPlan == .annual {
                Button {
                    openSubscriptionManagement()
                } label: {
                    HStack {
                        Label(Strings.Subscription.manageSubscription, systemImage: "gearshape")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Account setup issues (shown at the end, only when there are issues)
            if vm.hasAccountSetupIssues {
                AccountSetupBannerView(issues: vm.accountSetupIssues)
            }
            #endif
        } header: {
            Text(Strings.Subscription.sectionHeader)
        }
        .alert(Strings.Subscription.restorePurchases, isPresented: $showingRestoreAlert) {
            Button(Strings.Common.ok, role: .cancel) {}
        } message: {
            Text(restoreAlertMessage)
        }
    }

    // MARK: - Subscription Icon

    private var subscriptionIconConfig: (name: String, style: AnyShapeStyle) {
        switch vm.subscriptionPlan {
        case .free:
            return ("person.fill", AnyShapeStyle(Color.secondary))
        case .weekly, .monthly, .annual:
            return ("crown.fill", AnyShapeStyle(GradientTokens.premiumCrown))
        }
    }

    // MARK: - Actions

    private func showPaywall() {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await vm.showPaywall()
        }
    }

    private func openSubscriptionManagement() {
        // Open App Store subscription management
        // This deep links to the user's subscriptions in Settings/App Store
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            #if !os(macOS)
            UIApplication.shared.open(url)
            #endif
        }
    }

    private func restorePurchases() async {
        isRestoringPurchases = true

        // Use ViewModel's restore method which properly:
        // 1. Syncs with App Store
        // 2. Restores via PaywallService (registers in cache)
        // 3. Refreshes subscription status
        // 4. Notifies app of status change
        let result = await vm.restorePurchases()

        if result.success {
            restoreAlertMessage = Strings.Subscription.restoredPurchases(result.count)
        } else if result.message.contains("No purchases") {
            restoreAlertMessage = Strings.Subscription.noPurchasesToRestore
        } else {
            restoreAlertMessage = Strings.Subscription.restoreFailed
        }

        showingRestoreAlert = true
        isRestoringPurchases = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Form {
            // Free user preview
            SubscriptionManagementSectionView(vm: makePreviewVM(plan: .free))

            // Monthly subscriber preview
            SubscriptionManagementSectionView(vm: makePreviewVM(plan: .monthly, expiryDate: Date().addingTimeInterval(BusinessConstants.thirtyDaysInterval)))

            // Annual subscriber preview
            SubscriptionManagementSectionView(vm: makePreviewVM(plan: .annual, expiryDate: Date().addingTimeInterval(BusinessConstants.oneYearInterval)))
        }
        .navigationTitle("Subscription Previews")
    }
}

// MARK: - Preview Helpers

@MainActor
private func makePreviewVM(plan: SubscriptionPlan, expiryDate: Date? = nil, isOnTrial: Bool = false) -> SettingsViewModel {
    let profile = UserProfile()

    let vm = SettingsViewModel(
        loadProfile: MockLoadProfile(profile: profile),
        saveProfile: MockSaveProfile(),
        permissionCoordinator: MockPermissionCoordinator(),
        checkNotificationStatus: MockCheckNotificationStatus(),
        getLocationAuthStatus: MockGetLocationAuthStatus(),
        clearPurchases: MockClearPurchases(),
        checkPremiumStatus: MockCheckPremiumStatus(isPremium: plan.isPremium),
        getCurrentSubscriptionPlan: MockGetCurrentSubscriptionPlan(plan: plan),
        getSubscriptionExpiryDate: MockGetSubscriptionExpiryDate(expiryDate: expiryDate),
        getIsOnTrial: MockGetIsOnTrial(isOnTrial: isOnTrial),
        syncWithiCloud: MockSyncWithiCloud(),
        checkiCloudStatus: MockCheckiCloudStatus(),
        getLastSyncDate: MockGetLastSyncDate(),
        deleteData: MockDeleteData(),
        exportUserData: MockExportUserData(),
        importUserData: MockImportUserData()
    )

    return vm
}

// MARK: - Preview Mocks

private struct MockLoadProfile: LoadProfileUseCase {
    let profile: UserProfile

    func execute() async throws -> UserProfile {
        profile
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
    let isPremium: Bool

    func execute() async -> Bool { isPremium }
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
        Date().addingTimeInterval(-3600)
    }
}

private struct MockGetCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase {
    let plan: SubscriptionPlan

    func execute() async -> SubscriptionPlan { plan }
}

private struct MockGetSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase {
    let expiryDate: Date?

    func execute() async -> Date? { expiryDate }
}

private struct MockGetIsOnTrial: GetIsOnTrialUseCase {
    let isOnTrial: Bool

    func execute() async -> Bool { isOnTrial }
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
