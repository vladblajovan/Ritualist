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
        }
    }

    @MainActor
    private func clearAppBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
        logger.log("Cleared app badge", level: .info, category: .debug)
    }
}
#endif
