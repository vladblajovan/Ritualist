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
                Label("Mode", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("All Features Unlocked")
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
            HStack {
                Label("Status", systemImage: subscriptionIcon)
                    .foregroundStyle(.primary)

                Spacer()

                subscriptionStatusBadge
            }
            #endif

            #if !ALL_FEATURES_ENABLED
            // Subscribe Button (for free users only)
            if vm.subscriptionPlan == .free {
                Button {
                    showPaywall()
                } label: {
                    HStack {
                        Label("Subscribe to Pro", systemImage: "crown.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Expiry Date Row (for time-limited subscriptions)
            if let expiryDate = vm.subscriptionExpiryDate,
               vm.subscriptionPlan != .lifetime {
                HStack {
                    Label("Renews", systemImage: "calendar")
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
                            Text("Restoring...")
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                        }
                    }
                }
                .disabled(isRestoringPurchases)
            }

            // Manage Subscription Button (for active subscriptions only)
            if vm.subscriptionPlan == .monthly || vm.subscriptionPlan == .annual {
                Button {
                    openSubscriptionManagement()
                } label: {
                    HStack {
                        Label("Manage Subscription", systemImage: "gearshape")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            #endif

        } header: {
            Text("Subscription")
        } footer: {
            footerText
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreAlertMessage)
        }
    }

    // MARK: - Subscription Icon

    private var subscriptionIcon: String {
        switch vm.subscriptionPlan {
        case .free:
            return "person"
        case .monthly, .annual:
            return "star.circle.fill"
        case .lifetime:
            return "crown.fill"
        }
    }

    // MARK: - Subscription Status Badge

    @ViewBuilder
    private var subscriptionStatusBadge: some View {
        HStack(spacing: 6) {
            statusIndicator
            Text(vm.subscriptionPlan.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch vm.subscriptionPlan {
        case .free:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .font(.caption2)
        case .monthly, .annual:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .lifetime:
            Image(systemName: "infinity.circle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }

    private var statusColor: Color {
        switch vm.subscriptionPlan {
        case .free:
            return .secondary
        case .monthly, .annual:
            return .green
        case .lifetime:
            return .orange
        }
    }

    // MARK: - Footer Text

    @ViewBuilder
    private var footerText: some View {
        #if ALL_FEATURES_ENABLED
        Text("All premium features are unlocked in this build for testing purposes. This is a TestFlight/development build.")
        #else
        switch vm.subscriptionPlan {
        case .free:
            Text("Upgrade to Ritualist Pro to unlock unlimited habits, advanced analytics, and premium features.")
        case .monthly:
            Text("Your monthly subscription gives you access to all premium features. Manage or cancel anytime in App Store.")
        case .annual:
            Text("Your annual subscription includes all premium features. You can manage or cancel anytime in App Store.")
        case .lifetime:
            Text("You have lifetime access to all premium features. Thank you for your support!")
        }
        #endif
    }

    // MARK: - Actions

    private func showPaywall() {
        vm.showPaywall()
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
                restoreAlertMessage = "Successfully restored \(restoredProducts.count) purchase(s)."
            } else {
                restoreAlertMessage = "No purchases found to restore."
            }

            showingRestoreAlert = true

        } catch {
            restoreAlertMessage = "Failed to restore purchases. Please try again later."
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
            SubscriptionManagementSectionView(vm: makePreviewVM(plan: .monthly, expiryDate: Date().addingTimeInterval(30*24*60*60)))

            // Annual subscriber preview
            SubscriptionManagementSectionView(vm: makePreviewVM(plan: .annual, expiryDate: Date().addingTimeInterval(365*24*60*60)))

            // Lifetime access preview
            SubscriptionManagementSectionView(vm: makePreviewVM(plan: .lifetime))
        }
        .navigationTitle("Subscription Previews")
    }
}

// MARK: - Preview Helpers

@MainActor
private func makePreviewVM(plan: SubscriptionPlan, expiryDate: Date? = nil) -> SettingsViewModel {
    var profile = UserProfile()
    profile.subscriptionPlan = plan
    profile.subscriptionExpiryDate = expiryDate

    let vm = SettingsViewModel(
        loadProfile: MockLoadProfile(profile: profile),
        saveProfile: MockSaveProfile(),
        requestNotificationPermission: MockRequestNotificationPermission(),
        checkNotificationStatus: MockCheckNotificationStatus(),
        requestLocationPermissions: MockRequestLocationPermissions(),
        getLocationAuthStatus: MockGetLocationAuthStatus(),
        clearPurchases: MockClearPurchases(),
        checkPremiumStatus: MockCheckPremiumStatus(isPremium: plan.isPremium),
        updateUserSubscription: MockUpdateUserSubscription(),
        syncWithiCloud: MockSyncWithiCloud(),
        checkiCloudStatus: MockCheckiCloudStatus(),
        getLastSyncDate: MockGetLastSyncDate(),
        updateLastSyncDate: MockUpdateLastSyncDate()
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
    let isPremium: Bool

    func execute() async -> Bool { isPremium }
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
        Date().addingTimeInterval(-3600)
    }
}

private struct MockUpdateLastSyncDate: UpdateLastSyncDateUseCase {
    func execute(_ date: Date) async {}
}
