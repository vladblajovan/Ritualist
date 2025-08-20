//
//  UtilitiesLightTests.swift
//  RitualistTests
//
//  Created by Claude on 04.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

/// Lightweight utility tests that should run quickly without hanging
struct UtilitiesLightTests {
    
    // MARK: - NumberUtils Light Tests
    
    @Test("NumberUtils formats basic values correctly")
    func numberUtilsBasic() {
        #expect(NumberUtils.formatHabitValue(5.0) == "5")
        #expect(NumberUtils.formatHabitValue(3.14).contains("3"))
        #expect(NumberUtils.formatHabitValue(0.0) == "0")
    }
    
    @Test("NumberUtils parses values correctly")
    func numberUtilsParsing() {
        #expect(NumberUtils.parseHabitValue("42") == 42.0)
        
        // Test decimal parsing - check what the formatter actually produces
        let formatter = NumberUtils.habitValueFormatter()
        let formattedValue = formatter.string(from: NSNumber(value: 3.14)) ?? "3.14"
        let parsedValue = NumberUtils.parseHabitValue(formattedValue)
        #expect(parsedValue == 3.14)
        
        #expect(NumberUtils.parseHabitValue("invalid") == nil)
    }
    
    @Test("NumberUtils formats percentages correctly")
    func numberUtilsPercentages() {
        let result = NumberUtils.formatPercentage(0.75)
        #expect(result.contains("75"))
        #expect(result.contains("%"))
    }
    
    // MARK: - DateUtils Light Tests
    
    @Test("DateUtils handles same day comparisons")
    func dateUtilsSameDay() {
        let calendar = DateUtils.userCalendar()
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 8))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 20))!
        
        #expect(DateUtils.isSameDay(date1, date2, calendar: calendar) == true)
    }
    
    @Test("DateUtils calculates days between correctly")
    func dateUtilsDaysBetween() {
        let calendar = DateUtils.userCalendar()
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 4))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 5))!
        
        let result = DateUtils.daysBetween(date1, date2, calendar: calendar)
        #expect(result == 1)
    }
    
    @Test("DateUtils provides ordered weekday symbols")
    func dateUtilsWeekdaySymbols() {
        let symbols = DateUtils.orderedWeekdaySymbols()
        #expect(symbols.count == 7)
        
        for symbol in symbols {
            #expect(!symbol.isEmpty)
        }
    }
    
    // MARK: - UserActionEventMapper Light Tests
    
    @Test("UserActionEventMapper handles basic events")
    func eventMapperBasic() {
        let mapper = UserActionEventMapper()
        
        #expect(mapper.eventName(for: .onboardingStarted) == "onboarding_started")
        #expect(mapper.eventName(for: .settingsOpened) == "settings_opened")
        
        let properties = mapper.eventProperties(for: .onboardingStarted)
        #expect(properties.isEmpty)
    }
    
    @Test("UserActionEventMapper handles events with parameters")
    func eventMapperWithParameters() {
        let mapper = UserActionEventMapper()
        let event = UserActionEvent.screenViewed(screen: "habits")
        
        #expect(mapper.eventName(for: event) == "screen_viewed")
        
        let properties = mapper.eventProperties(for: event)
        #expect(properties["screen"] as? String == "habits")
    }
    
    @Test("UserActionEventMapper handles custom events")
    func eventMapperCustomEvents() {
        let mapper = UserActionEventMapper()
        let customProperties: [String: Any] = ["test": "value"]
        let event = UserActionEvent.custom(event: "test_event", parameters: customProperties)
        
        #expect(mapper.eventName(for: event) == "test_event")
        
        let properties = mapper.eventProperties(for: event)
        #expect(properties["test"] as? String == "value")
    }
    
    // MARK: - DebugLogger Light Tests (Minimal)
    
    @Test("DebugLogger creates basic log entries")
    func debugLoggerBasic() {
        let logger = DebugLogger()
        
        // Just test that logging doesn't crash
        logger.log("Test message")
        logger.log("Warning message", level: .warning)
        
        // Test that we can get recent logs without hanging
        let recentLogs = logger.getRecentLogs(limit: 5)
        #expect(recentLogs.count >= 1)
    }
    
    @Test("DebugLogger handles different log levels")
    func debugLoggerLevels() {
        #expect(LogLevel.debug.rawValue == "DEBUG")
        #expect(LogLevel.info.rawValue == "INFO")
        #expect(LogLevel.warning.rawValue == "WARNING")
        #expect(LogLevel.error.rawValue == "ERROR")
        #expect(LogLevel.critical.rawValue == "CRITICAL")
    }
    
    @Test("DebugLogger handles different categories")
    func debugLoggerCategories() {
        #expect(LogCategory.system.rawValue == "System")
        #expect(LogCategory.ui.rawValue == "UI")
        #expect(LogCategory.network.rawValue == "Network")
        #expect(LogCategory.performance.rawValue == "Performance")
    }
}
