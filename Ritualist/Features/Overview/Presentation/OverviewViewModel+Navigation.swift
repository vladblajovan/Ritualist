//
//  OverviewViewModel+Navigation.swift
//  Ritualist
//
//  Date navigation methods extracted from OverviewViewModel to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Date Navigation Methods

extension OverviewViewModel {

    /// Navigate to previous day.
    public func goToPreviousDay() {
        guard canGoToPreviousDay else { return }

        viewingDate = CalendarUtils.addDaysLocal(-1, to: viewingDate, timezone: displayTimezone)

        if checkMigrationAndInvalidateCache() {
            Task { @MainActor in await loadData() }
            return
        }

        if needsReload(for: viewingDate) {
            hasLoadedInitialData = false
            Task { @MainActor in await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    /// Navigate to next day.
    public func goToNextDay() {
        guard canGoToNextDay else { return }

        viewingDate = CalendarUtils.addDaysLocal(1, to: viewingDate, timezone: displayTimezone)

        if checkMigrationAndInvalidateCache() {
            Task { @MainActor in await loadData() }
            return
        }

        if needsReload(for: viewingDate) {
            hasLoadedInitialData = false
            Task { @MainActor in await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    /// Navigate to today.
    public func goToToday() {
        viewingDate = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)

        if checkMigrationAndInvalidateCache() {
            Task { @MainActor in await loadData() }
            return
        }

        if needsReload(for: Date()) {
            hasLoadedInitialData = false
            Task { @MainActor in await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    /// Navigate to a specific date.
    public func goToDate(_ date: Date) {
        viewingDate = CalendarUtils.startOfDayLocal(for: date, timezone: displayTimezone)

        if checkMigrationAndInvalidateCache() {
            Task { @MainActor in await loadData() }
            return
        }

        if needsReload(for: date) {
            hasLoadedInitialData = false
            Task { @MainActor in await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    /// Check if date requires database reload (outside cached range).
    func needsReload(for date: Date) -> Bool {
        guard let data = overviewData else {
            logger.log("Reload needed - no cache available", level: .debug, category: .stateManagement)
            return true
        }
        let dateStart = CalendarUtils.startOfDayLocal(for: date, timezone: displayTimezone)
        let needsReload = !data.dateRange.contains(dateStart)
        if needsReload {
            logger.log("Reload needed - date outside cached range", level: .debug, category: .stateManagement, metadata: ["date": dateStart.description])
        } else {
            logger.log("Cache hit - date within range", level: .debug, category: .stateManagement, metadata: ["date": dateStart.description])
        }
        return needsReload
    }
}
