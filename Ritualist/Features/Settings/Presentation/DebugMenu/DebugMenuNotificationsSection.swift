//
//  DebugMenuNotificationsSection.swift
//  Ritualist
//

import SwiftUI
import RitualistCore
import FactoryKit
import UserNotifications

#if DEBUG
struct DebugMenuNotificationsSection: View {
    @Injected(\.debugLogger) private var logger
    @Injected(\.userDefaultsService) private var userDefaultsService

    @State private var showingCatchUpResetConfirmation = false

    var body: some View {
        Section("Notifications") {
            Button {
                Task {
                    await clearAppBadge()
                }
            } label: {
                HStack {
                    Image(systemName: "app.badge")
                        .foregroundColor(.red)

                    Text("Clear App Badge")

                    Spacer()
                }
            }

            Text("Removes any stuck badge count from the app icon.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                resetCatchUpTracking()
                showingCatchUpResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "bell.badge.slash")
                        .foregroundColor(.orange)

                    Text("Reset \"Don't Forget\" Tracking")

                    Spacer()
                }
            }
            .alert("Tracking Reset", isPresented: $showingCatchUpResetConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Catch-up notification tracking has been cleared. \"Don't forget\" notifications can now be triggered again for all habits.")
            }

            Text("Clears the record of which habits have received catch-up notifications today. Allows \"Don't forget\" notifications to be triggered again.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @MainActor
    private func clearAppBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
        logger.log("Cleared app badge", level: .info, category: .debug)
    }

    private func resetCatchUpTracking() {
        userDefaultsService.removeObject(forKey: UserDefaultsKeys.catchUpDeliveredHabitIds)
        userDefaultsService.removeObject(forKey: UserDefaultsKeys.catchUpDeliveryDate)
        logger.log("Reset catch-up notification tracking", level: .info, category: .debug)
    }
}
#endif
