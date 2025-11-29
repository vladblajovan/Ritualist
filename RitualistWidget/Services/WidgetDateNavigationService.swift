//
//  WidgetDateNavigationService.swift
//  RitualistWidget
//
//  Created by Claude on 28.08.2025.
//

import Foundation
import RitualistCore

/// Service for managing widget date navigation following main app patterns
/// Handles date state persistence and navigation boundaries consistently
public protocol WidgetDateNavigationServiceProtocol {
    var currentDate: Date { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var isViewingToday: Bool { get }
    
    func navigateToPrevious() -> Bool
    func navigateToNext() -> Bool
    func navigateToToday()
    func setDate(_ date: Date) -> Bool
}

public final class WidgetDateNavigationService: WidgetDateNavigationServiceProtocol {

    // MARK: - Constants

    private static let selectedDateKey = "widget_selected_date"
    private static let maxHistoryDays = 30

    // MARK: - Properties

    private let sharedDefaults: UserDefaults?
    private let calendar = CalendarUtils.currentLocalCalendar
    private let logger = DebugLogger(subsystem: WidgetConstants.loggerSubsystem, category: "navigation")
    
    // MARK: - Initialization
    
    public init() {
        self.sharedDefaults = UserDefaults(suiteName: WidgetConstants.appGroupIdentifier)
        
        // Initialize with today's date if no stored date exists
        initializeDateIfNeeded()
    }
    
    // MARK: - Public Interface
    
    public var currentDate: Date {
        guard let sharedDefaults = sharedDefaults else {
            return normalizedToday
        }
        
        let storedDate = sharedDefaults.object(forKey: Self.selectedDateKey) as? Date
        let today = normalizedToday
        
        // Return stored date if valid, otherwise today
        if let date = storedDate, isDateWithinBounds(date) {
            let normalizedStoredDate = calendar.startOfDay(for: date)
            return normalizedStoredDate
        }
        
        return today
    }
    
    public var canGoBack: Bool {
        let current = currentDate
        let earliestAllowed = earliestAllowedDate
        return current > earliestAllowed
    }
    
    public var canGoForward: Bool {
        let current = currentDate
        return current < normalizedToday
    }
    
    public var isViewingToday: Bool {
        let current = currentDate
        let today = Date()
        return CalendarUtils.areSameDayLocal(current, today)
    }
    
    @discardableResult
    public func navigateToPrevious() -> Bool {
        let current = currentDate
        
        guard canGoBack else {
            logger.log("Cannot navigate to previous day - at boundary", level: .debug, category: .ui)
            return false
        }

        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: current) else {
            logger.log("Date calculation failed for previous day", level: .error, category: .ui)
            return false
        }

        logger.log("Navigating to previous day: \(previousDate)", level: .debug, category: .ui)
        return setDate(previousDate)
    }
    
    @discardableResult
    public func navigateToNext() -> Bool {
        let current = currentDate
        
        guard canGoForward else {
            logger.log("Cannot navigate to next day - at boundary", level: .debug, category: .ui)
            return false
        }

        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: current) else {
            logger.log("Date calculation failed for next day", level: .error, category: .ui)
            return false
        }

        logger.log("Navigating to next day: \(nextDate)", level: .debug, category: .ui)
        return setDate(nextDate)
    }
    
    public func navigateToToday() {
        logger.log("Navigating to today", level: .debug, category: .ui)
        setDate(normalizedToday)
    }
    
    @discardableResult
    public func setDate(_ date: Date) -> Bool {
        guard let sharedDefaults = sharedDefaults else {
            logger.log("Cannot set date - no shared defaults", level: .warning, category: .dataIntegrity)
            return false
        }

        let normalizedDate = calendar.startOfDay(for: date)

        guard isDateWithinBounds(normalizedDate) else {
            logger.log("Date out of bounds: \(normalizedDate)", level: .debug, category: .ui)
            return false
        }

        sharedDefaults.set(normalizedDate, forKey: Self.selectedDateKey)
        logger.log("Successfully set date: \(normalizedDate)", level: .debug, category: .ui)

        return true
    }
    
    // MARK: - Private Helpers
    
    private var normalizedToday: Date {
        return calendar.startOfDay(for: Date())
    }
    
    private var earliestAllowedDate: Date {
        return CalendarUtils.addDaysLocal(-Self.maxHistoryDays, to: normalizedToday, timezone: .current)
    }
    
    private func isDateWithinBounds(_ date: Date) -> Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        let today = normalizedToday
        let earliest = earliestAllowedDate
        
        return normalizedDate >= earliest && normalizedDate <= today
    }
    
    private func initializeDateIfNeeded() {
        guard let sharedDefaults = sharedDefaults else {
            logger.log("Cannot initialize - no shared defaults", level: .warning, category: .dataIntegrity)
            return
        }

        let storedDate = sharedDefaults.object(forKey: Self.selectedDateKey) as? Date
        let today = normalizedToday

        if storedDate == nil {
            sharedDefaults.set(today, forKey: Self.selectedDateKey)
            logger.log("Initialized with today: \(today)", level: .debug, category: .ui)
        } else if let date = storedDate, !isDateWithinBounds(date) {
            // Reset to today if stored date is out of bounds
            sharedDefaults.set(today, forKey: Self.selectedDateKey)
            logger.log("Reset out-of-bounds date to today: \(today)", level: .debug, category: .ui)
        } else if let date = storedDate {
            logger.log("Using stored date: \(date)", level: .debug, category: .ui)
        }
    }
}