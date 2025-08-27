//
//  WidgetDateState.swift
//  RitualistWidget
//
//  Created by Claude on 19.08.2025.
//

import Foundation
import Factory
import RitualistCore

// MARK: - Widget Date State Management

/// Manages the selected date state for widget navigation
/// Persists state using App Group shared UserDefaults for cross-widget consistency
public final class WidgetDateState {
    
    // MARK: - Constants
    
    /// App Group identifier for shared UserDefaults
    private static let appGroupIdentifier = "group.com.vladblajovan.Ritualist"
    
    /// UserDefaults key for storing selected date
    private static let selectedDateKey = "widget_selected_date"
    
    /// Date validation service for consistent boundary checks
    @Injected(\.historicalDateValidationService) private var dateValidationService
    
    // MARK: - Properties
    
    /// Shared UserDefaults instance for App Group
    private let sharedDefaults: UserDefaults?
    
    /// Calendar instance for date calculations
    private let calendar = Calendar.current
    
    /// Serial queue for thread-safe operations
    private let queue = DispatchQueue(label: "widget.datestate", qos: .utility)
    
    // MARK: - Initialization
    
    /// Singleton instance for consistent state across widget components
    public static let shared = WidgetDateState()
    
    private init() {
        self.sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        
        // Debug app group initialization
        if self.sharedDefaults != nil {
            print("[WIDGET-DATE-STATE] App Group UserDefaults initialized successfully")
            print("[WIDGET-DATE-STATE] App Group ID: \(Self.appGroupIdentifier)")
            
            // CRITICAL BUG FIX: Ensure widget always starts with today on first launch
            ensureValidInitialDate()
        } else {
            print("[WIDGET-DATE-STATE] WARNING: App Group UserDefaults failed to initialize!")
            print("[WIDGET-DATE-STATE] App Group ID: \(Self.appGroupIdentifier)")
        }
    }
    
    /// Ensures the widget starts with today's date if no valid date is stored
    /// This fixes the critical bug where widget defaulted to yesterday
    private func ensureValidInitialDate() {
        guard let sharedDefaults = sharedDefaults else { return }
        
        let storedDate = sharedDefaults.object(forKey: Self.selectedDateKey) as? Date
        let today = normalizedToday
        
        if let stored = storedDate {
            print("[WIDGET-DATE-STATE] Found stored date: \(stored)")
            
            // Check if stored date is valid using service
            if !dateValidationService.isDateWithinBounds(stored) {
                print("[WIDGET-DATE-STATE] Stored date is invalid, resetting to today")
                sharedDefaults.set(today, forKey: Self.selectedDateKey)
            }
        } else {
            print("[WIDGET-DATE-STATE] No stored date found, initializing to today: \(today)")
            sharedDefaults.set(today, forKey: Self.selectedDateKey)
        }
    }
    
    // MARK: - Public Interface
    
    /// The currently selected date, normalized to start of day
    /// Returns today if no date is persisted or if persisted date is invalid
    public var currentDate: Date {
        return queue.sync {
            let today = normalizedToday
            print("[WIDGET-DATE-STATE] currentDate called - today is: \(today)")
            
            guard let sharedDefaults = sharedDefaults else {
                print("[WIDGET-DATE-STATE] No shared defaults available, returning today: \(today)")
                return today
            }
            
            // Retrieve stored date
            let storedDate = sharedDefaults.object(forKey: Self.selectedDateKey) as? Date
            print("[WIDGET-DATE-STATE] Retrieved stored date: \(storedDate?.description ?? "nil")")
            
            // Validate stored date is within bounds using service
            if let date = storedDate {
                let normalizedStoredDate = calendar.startOfDay(for: date)
                let isWithinBounds = dateValidationService.isDateWithinBounds(date)
                print("[WIDGET-DATE-STATE] Stored date normalized: \(normalizedStoredDate), within bounds: \(isWithinBounds)")
                
                if isWithinBounds {
                    print("[WIDGET-DATE-STATE] Returning valid stored date: \(normalizedStoredDate)")
                    return normalizedStoredDate
                } else {
                    print("[WIDGET-DATE-STATE] Stored date out of bounds, returning today: \(today)")
                    return today
                }
            }
            
            // Return today if no valid stored date
            print("[WIDGET-DATE-STATE] No stored date found, returning today: \(today)")
            return today
        }
    }
    
    /// Navigate to previous day if possible
    /// Returns true if navigation was successful, false if already at boundary
    @discardableResult
    public func navigateToPrevious() -> Bool {
        return queue.sync {
            // Get current date directly without recursive queue.sync
            let currentDate = getCurrentDateInternal()
            
            // Check boundary condition using validation service
            let earliestAllowed = dateValidationService.getEarliestAllowedDate()
            guard currentDate > earliestAllowed else { 
                print("[WIDGET-DATE-STATE] Cannot navigate to previous day - at earliest boundary")
                return false 
            }
            
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                print("[WIDGET-DATE-STATE] Cannot navigate to previous day - date calculation failed")
                return false
            }
            
            print("[WIDGET-DATE-STATE] Navigating to previous day: \(previousDate)")
            return setSelectedDate(previousDate)
        }
    }
    
    /// Navigate to next day if possible
    /// Returns true if navigation was successful, false if already at boundary
    @discardableResult
    public func navigateToNext() -> Bool {
        return queue.sync {
            // Get current date directly without recursive queue.sync
            let currentDate = getCurrentDateInternal()
            
            // Check boundary condition directly to avoid recursive queue.sync
            guard currentDate < normalizedToday else { 
                print("[WIDGET-DATE-STATE] Cannot navigate to next day - already at today")
                return false 
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                print("[WIDGET-DATE-STATE] Cannot navigate to next day - date calculation failed")
                return false
            }
            
            print("[WIDGET-DATE-STATE] Navigating to next day: \(nextDate)")
            return setSelectedDate(nextDate)
        }
    }
    
    /// Navigate to today's date
    public func navigateToToday() {
        queue.sync {
            setSelectedDate(normalizedToday)
        }
    }
    
    /// Check if user can navigate to previous day
    public var canGoBack: Bool {
        let current = currentDate
        let earliestAllowed = dateValidationService.getEarliestAllowedDate()
        return current > earliestAllowed
    }
    
    /// Check if user can navigate to next day
    public var canGoForward: Bool {
        let current = currentDate
        return current < normalizedToday
    }
    
    /// Check if currently viewing today's date
    public var isViewingToday: Bool {
        return calendar.isDate(currentDate, inSameDayAs: normalizedToday)
    }
    
    // MARK: - Private Helpers
    
    /// Today's date normalized to start of day
    /// Uses a consistent calendar instance to avoid timezone/midnight edge cases
    private var normalizedToday: Date {
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        print("[WIDGET-DATE-STATE] normalizedToday calculated - now: \(now), today start: \(todayStart), calendar: \(calendar.timeZone)")
        return todayStart
    }
    
    /// Internal method to get current date without queue.sync (for use within sync blocks)
    private func getCurrentDateInternal() -> Date {
        guard let sharedDefaults = sharedDefaults else {
            print("[WIDGET-DATE-STATE] No shared defaults available, returning today")
            return normalizedToday
        }
        
        // Retrieve stored date
        let storedDate = sharedDefaults.object(forKey: Self.selectedDateKey) as? Date
        
        // Validate stored date is within bounds using service
        if let date = storedDate, dateValidationService.isDateWithinBounds(date) {
            return calendar.startOfDay(for: date)
        }
        
        // Return today if no valid stored date
        print("[WIDGET-DATE-STATE] No valid stored date, returning today")
        return normalizedToday
    }
    
    /// Set the selected date with validation
    /// Returns true if successful, false if date is invalid
    @discardableResult
    private func setSelectedDate(_ date: Date) -> Bool {
        print("[WIDGET-DATE-STATE] setSelectedDate called with: \(date)")
        
        guard let sharedDefaults = sharedDefaults else { 
            print("[WIDGET-DATE-STATE] setSelectedDate failed - no shared defaults")
            return false 
        }
        
        let normalizedDate = calendar.startOfDay(for: date)
        print("[WIDGET-DATE-STATE] normalized date: \(normalizedDate)")
        
        // Validate date is within allowed bounds using service
        guard dateValidationService.isDateWithinBounds(normalizedDate) else { 
            print("[WIDGET-DATE-STATE] setSelectedDate failed - date out of bounds")
            return false 
        }
        
        // Persist the date
        sharedDefaults.set(normalizedDate, forKey: Self.selectedDateKey)
        print("[WIDGET-DATE-STATE] Successfully set date: \(normalizedDate)")
        
        return true
    }
    
}

// MARK: - Debug Support

#if DEBUG
extension WidgetDateState {
    
    /// Reset state for testing purposes
    /// Only available in debug builds
    func resetForTesting() {
        queue.sync {
            print("[WIDGET-DATE-STATE-DEBUG] Resetting stored date for testing")
            sharedDefaults?.removeObject(forKey: Self.selectedDateKey)
        }
    }
    
    /// Get the raw stored date for testing
    /// Only available in debug builds
    func getStoredDateForTesting() -> Date? {
        return queue.sync {
            let storedDate = sharedDefaults?.object(forKey: Self.selectedDateKey) as? Date
            print("[WIDGET-DATE-STATE-DEBUG] Raw stored date: \(storedDate?.description ?? "nil")")
            return storedDate
        }
    }
    
    /// Force set date for testing (bypasses validation)
    /// Only available in debug builds
    func forceSetDateForTesting(_ date: Date) {
        queue.sync {
            print("[WIDGET-DATE-STATE-DEBUG] Force setting date for testing: \(date)")
            sharedDefaults?.set(date, forKey: Self.selectedDateKey)
        }
    }
    
    /// Clear any stored date and force initialization to today
    func clearStoredDateAndReinitialize() {
        queue.sync {
            print("[WIDGET-DATE-STATE-DEBUG] Clearing stored date and reinitializing to today")
            sharedDefaults?.removeObject(forKey: Self.selectedDateKey)
            print("[WIDGET-DATE-STATE-DEBUG] Current date after clear: \(currentDate)")
        }
    }
}
#endif