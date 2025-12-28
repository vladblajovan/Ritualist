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
                Task {
                    await clearMockPurchases()
                }
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.orange)

                    Text("Clear Mock Purchases")

                    Spacer()
                }
            }
            .disabled(vm.subscriptionPlan == .free)

            Text("Clears mock subscription from UserDefaults to test free tier")
                .font(.caption)
                .foregroundColor(.secondary)
            #else
            Text("Subscription testing is not available in AllFeatures mode")
                .font(.caption)
                .foregroundColor(.secondary)
            #endif

            Button(role: .destructive) {
                Task {
                    await SecurePremiumCache.shared.clearCache()
                }
            } label: {
                HStack {
                    Image(systemName: "key.slash")
                        .foregroundColor(.red)

                    Text("Clear Premium Cache (Keychain)")

                    Spacer()
                }
            }

            Text("Clears the Keychain-cached premium status for testing feature gating (habit limits). iCloud sync is always enabled regardless of premium status.")
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
}
#endif
