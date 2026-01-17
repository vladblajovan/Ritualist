//
//  DebugMenuSubscriptionSection.swift
//  Ritualist
//

import SwiftUI
import RitualistCore
import FactoryKit

#if DEBUG
struct DebugMenuSubscriptionSection: View {
    @Bindable var vm: SettingsViewModel
    @Injected(\.debugLogger) private var logger
    @State private var showingClearMockPurchasesConfirmation = false
    @State private var showingClearPremiumCacheConfirmation = false

    var body: some View {
        Section("Subscription Testing") {
            #if !ALL_FEATURES_ENABLED
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Subscription")
                        .font(.headline)
                    Spacer()
                    Text(vm.subscriptionPlan.displayName)
                        .fontWeight(.medium)
                        .foregroundColor(subscriptionColor(for: vm.subscriptionPlan))
                }

                if vm.subscriptionPlan != .free {
                    Text("Mock subscription stored in UserDefaults")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            Button(role: .destructive) {
                showingClearMockPurchasesConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.orange)

                    Text("Clear Mock Purchases")

                    Spacer()
                }
            }
            .disabled(vm.subscriptionPlan == .free)
            .alert("Clear Mock Purchases?", isPresented: $showingClearMockPurchasesConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await clearMockPurchases()
                    }
                }
            } message: {
                Text("This will reset subscription to free tier for testing.")
            }

            Text("Clears mock subscription from UserDefaults to test free tier")
                .font(.caption)
                .foregroundColor(.secondary)
            #else
            Text("Subscription testing is not available in AllFeatures mode")
                .font(.caption)
                .foregroundColor(.secondary)
            #endif

            Button(role: .destructive) {
                showingClearPremiumCacheConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "key.slash")
                        .foregroundColor(.red)

                    Text("Force Reset to Free User")

                    Spacer()
                }
            }
            .alert("Force Reset to Free User?", isPresented: $showingClearPremiumCacheConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await forceResetToFreeUser()
                    }
                }
            } message: {
                Text("This will clear ALL premium caches (Keychain + in-memory) and refresh subscription status. Use after deleting StoreKit transactions in Xcode.")
            }

            Text("Clears ALL premium caches and forces subscription status refresh. Use this after deleting StoreKit transactions to immediately become a free user.")
                .font(.caption)
                .foregroundColor(.secondary)

            // MARK: - Billing Issue Testing

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Billing Issue Status")
                        .font(.headline)
                    Spacer()
                    Text(vm.hasBillingIssue ? "Active" : "None")
                        .fontWeight(.medium)
                        .foregroundColor(vm.hasBillingIssue ? .orange : .secondary)
                }

                Text("Simulates Apple's billing dialog being shown/dismissed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)

            Button {
                Task { @MainActor in
                    await simulateBillingIssue()
                }
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Simulate Billing Issue")
                    Spacer()
                }
            }

            Text("Records a billing issue timestamp (as if user dismissed Apple's dialog). Use this to test the billing banner in Settings without relying on simulator dialog.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                Task { @MainActor in
                    await clearBillingIssue()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Clear Billing Issue")
                    Spacer()
                }
            }
            .disabled(!vm.hasBillingIssue)

            Text("Clears the billing issue flag (as if payment was resolved)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func subscriptionColor(for plan: SubscriptionPlan) -> Color {
        switch plan {
        case .free:
            return .secondary
        case .weekly, .monthly, .annual:
            return .green
        }
    }

    private func clearMockPurchases() async {
        do {
            try await vm.subscriptionService.clearPurchases()
            await vm.refreshSubscriptionStatus()
            logger.log("Cleared mock purchases", level: .info, category: .debug)
        } catch {
            logger.logError(error, context: "Failed to clear mock purchases")
        }
    }

    private func forceResetToFreeUser() async {
        do {
            // Clear ALL caches: in-memory + Keychain
            try await vm.subscriptionService.clearPurchases()

            // Force refresh subscription status from StoreKit
            await vm.refreshSubscriptionStatus()

            logger.log("Force reset to free user - all caches cleared", level: .info, category: .debug)
        } catch {
            logger.logError(error, context: "Failed to force reset to free user")
        }
    }

    private func simulateBillingIssue() async {
        // Record a billing issue as if user dismissed Apple's dialog
        await SecurePremiumCache.shared.recordBillingIssueDetected()

        // Refresh ViewModel to pick up the change
        await vm.refreshSubscriptionStatus()

        logger.log("Simulated billing issue - banner should now appear in Settings", level: .info, category: .debug)
    }

    private func clearBillingIssue() async {
        // Clear the billing issue flag as if payment was resolved
        await SecurePremiumCache.shared.clearBillingIssueFlag()

        // Refresh ViewModel to pick up the change
        await vm.refreshSubscriptionStatus()

        logger.log("Cleared billing issue - banner should disappear from Settings", level: .info, category: .debug)
    }
}
#endif
