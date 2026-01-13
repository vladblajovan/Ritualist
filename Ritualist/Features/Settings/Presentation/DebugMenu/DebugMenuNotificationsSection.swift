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

    @State private var showingClearBadgeConfirmation = false
    @State private var showingResetTrackingConfirmation = false
    @State private var showingClearSnoozeConfirmation = false
    @State private var showingClearFiredConfirmation = false

    var body: some View {
        Section("Notifications") {
            Button {
                showingClearBadgeConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "app.badge")
                        .foregroundColor(.red)

                    Text("Clear App Badge")

                    Spacer()
                }
            }
            .alert("Clear App Badge?", isPresented: $showingClearBadgeConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await clearAppBadge()
                    }
                }
            } message: {
                Text("This will reset the app badge count to zero.")
            }

            Text("Removes any stuck badge count from the app icon.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                showingResetTrackingConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "bell.badge.slash")
                        .foregroundColor(.orange)

                    Text("Reset \"Don't Forget\" Tracking")

                    Spacer()
                }
            }
            .alert("Reset Tracking?", isPresented: $showingResetTrackingConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetCatchUpTracking()
                }
            } message: {
                Text("This will clear the record of which habits have received catch-up notifications today. \"Don't forget\" notifications can trigger again for all habits.")
            }

            Text("Clears the record of which habits have received catch-up notifications today. Allows \"Don't forget\" notifications to be triggered again.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                showingClearSnoozeConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(.purple)

                    Text("Clear Pending Snooze Notifications")

                    Spacer()
                }
            }
            .alert("Clear Snooze Notifications?", isPresented: $showingClearSnoozeConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await clearPendingSnoozeNotifications()
                    }
                }
            } message: {
                Text("This will remove all pending snooze notifications. Use this to clear any stale notifications from old code.")
            }

            Text("Removes any pending snooze notifications that may be stale or from old code versions.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                showingClearFiredConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "bell.and.waves.left.and.right")
                        .foregroundColor(.blue)

                    Text("Clear Fired Notification IDs")

                    Spacer()
                }
            }
            .alert("Clear Fired Notification IDs?", isPresented: $showingClearFiredConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearFiredNotificationTracking()
                }
            } message: {
                Text("This will clear the record of which notifications have fired today. Notifications may fire again if app restarts within the same minute.")
            }

            Text("Clears the record of fired notifications. Use this to test duplicate notification prevention.")
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
        // Log what we're clearing for debugging
        let existingIds = userDefaultsService.stringArray(forKey: UserDefaultsKeys.catchUpDeliveredHabitIds) ?? []
        let existingDate = userDefaultsService.date(forKey: UserDefaultsKeys.catchUpDeliveryDate)

        // Remove both keys entirely (clears ALL tracked habit IDs)
        userDefaultsService.removeObject(forKey: UserDefaultsKeys.catchUpDeliveredHabitIds)
        userDefaultsService.removeObject(forKey: UserDefaultsKeys.catchUpDeliveryDate)

        logger.log(
            "Reset catch-up notification tracking",
            level: .info,
            category: .debug,
            metadata: [
                "cleared_habit_count": existingIds.count,
                "had_date": existingDate != nil
            ]
        )
    }

    private func clearFiredNotificationTracking() {
        // Log what we're clearing for debugging
        let existingIds = userDefaultsService.stringArray(forKey: UserDefaultsKeys.firedNotificationIds) ?? []
        let existingDate = userDefaultsService.date(forKey: UserDefaultsKeys.firedNotificationDate)

        // Remove both keys entirely
        userDefaultsService.removeObject(forKey: UserDefaultsKeys.firedNotificationIds)
        userDefaultsService.removeObject(forKey: UserDefaultsKeys.firedNotificationDate)

        logger.log(
            "Cleared fired notification tracking",
            level: .info,
            category: .debug,
            metadata: [
                "cleared_notification_count": existingIds.count,
                "had_date": existingDate != nil
            ]
        )
    }

    @MainActor
    private func clearPendingSnoozeNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        // Find all snooze notifications (ID starts with "snooze-")
        let snoozeIds = pendingRequests
            .filter { $0.identifier.hasPrefix("snooze-") }
            .map { $0.identifier }

        if !snoozeIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: snoozeIds)
            logger.log(
                "Cleared pending snooze notifications",
                level: .info,
                category: .debug,
                metadata: ["count": snoozeIds.count]
            )
        } else {
            logger.log("No pending snooze notifications to clear", level: .info, category: .debug)
        }
    }
}
#endif
