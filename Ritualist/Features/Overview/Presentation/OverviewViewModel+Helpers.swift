//
//  OverviewViewModel+Helpers.swift
//  Ritualist
//
//  Helper methods extracted from OverviewViewModel to reduce function body length.
//

import Foundation
import RitualistCore

// MARK: - Load Data Helpers

extension OverviewViewModel {

    /// Handles timezone updates and recalculates viewingDate when needed.
    ///
    /// Called during loadData() to ensure the display timezone is current
    /// and viewingDate reflects "today" in the user's configured timezone.
    ///
    /// - Parameters:
    ///   - newTimezone: The timezone fetched from user settings
    ///   - timezoneChanged: Whether the timezone differs from the previous value
    func handleTimezoneAndViewingDate(newTimezone: TimeZone, timezoneChanged: Bool) {
        // Update cached timezone
        displayTimezone = newTimezone

        // Recalculate viewingDate when:
        // 1. Timezone actually changed (user updated settings)
        // 2. True first load (viewingDate was initialized with device timezone, not user's setting)
        // Note: Use hasEverLoadedData to avoid resetting date during navigation-triggered reloads
        // This ensures MonthlyCalendarCard and TodaysSummaryCard show correct "today" highlighting
        if timezoneChanged || !hasEverLoadedData {
            let oldViewingDate = viewingDate
            viewingDate = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            logger.log(
                "Recalculated viewingDate for today",
                level: .info,
                category: .stateManagement,
                metadata: [
                    "reason": !hasEverLoadedData ? "first_load" : "timezone_changed",
                    "timezone": displayTimezone.identifier,
                    "oldViewingDate": oldViewingDate.description,
                    "newViewingDate": viewingDate.description
                ]
            )
        }

        logger.log(
            "Display timezone loaded",
            level: .debug,
            category: .stateManagement,
            metadata: ["timezone": displayTimezone.identifier]
        )
    }
}
