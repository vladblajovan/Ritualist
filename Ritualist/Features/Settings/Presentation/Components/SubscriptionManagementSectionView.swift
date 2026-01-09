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
            // Subscription Row (Production) - only show for premium users
            if vm.subscriptionPlan != .free {
                HStack {
                    // Show "Trial" when user is on trial, otherwise show plan name (Annual/Monthly/Weekly)
                    Label(vm.isOnTrial ? Strings.Subscription.trial : vm.subscriptionPlan.displayName, systemImage: subscriptionIcon)
                        .foregroundStyle(.primary)

                    Spacer()

                    CrownProBadge()
                }
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
                    Task {
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
        } footer: {
            footerText
        }
        .alert(Strings.Subscription.restorePurchases, isPresented: $showingRestoreAlert) {
            Button(Strings.Common.ok, role: .cancel) {}
        } message: {
            Text(restoreAlertMessage)
        }
    }

    // MARK: - Subscription Icon

    private var subscriptionIcon: String {
        switch vm.subscriptionPlan {
        case .free:
            return "person"
        case .weekly, .monthly, .annual:
            return "star.circle.fill"
        }
    }

    // MARK: - Footer Text

    @ViewBuilder
    private var footerText: some View {
        #if ALL_FEATURES_ENABLED
        Text(Strings.Subscription.allFeaturesFooter)
        #else
        // Don't show promotional footer for trial users
        if vm.isOnTrial {
            EmptyView()
        } else {
            switch vm.subscriptionPlan {
            case .free:
                Text(Strings.Subscription.freeFooter)
            case .weekly:
                Text(Strings.Subscription.weeklyFooter)
            case .monthly:
                Text(Strings.Subscription.monthlyFooter)
            case .annual:
                Text(Strings.Subscription.annualFooter)
            }
        }
        #endif
    }

    // MARK: - Actions

    private func showPaywall() {
        Task {
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

        // Use App Store StoreKit API to restore purchases
        do {
            // Sync with App Store to restore transactions
            try await AppStore.sync()

            // Check if any purchases were restored
            var restoredProducts: [String] = []
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    restoredProducts.append(transaction.productID)
                }
            }

            if !restoredProducts.isEmpty {
                restoreAlertMessage = Strings.Subscription.restoredPurchases(restoredProducts.count)
                // Notify the app that premium status changed so all UI updates immediately
                NotificationCenter.default.post(name: .premiumStatusDidChange, object: nil)
            } else {
                restoreAlertMessage = Strings.Subscription.noPurchasesToRestore
            }

            showingRestoreAlert = true
        } catch {
            restoreAlertMessage = Strings.Subscription.restoreFailed
            showingRestoreAlert = true
        }

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
