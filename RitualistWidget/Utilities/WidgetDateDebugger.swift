//
//  WidgetDateDebugger.swift
//  RitualistWidget
//
//  Created by Claude on 19.08.2025.
//

import Foundation

#if DEBUG
/// Debug utility to investigate and fix widget date initialization issues
public class WidgetDateDebugger {
    
    /// Check current stored widget date and log details
    public static func debugStoredDate() {
        print("[WIDGET-DATE-DEBUGGER] === WIDGET DATE DEBUG REPORT ===")
        
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        
        print("[WIDGET-DATE-DEBUGGER] Current time: \(now)")
        print("[WIDGET-DATE-DEBUGGER] Today start: \(today)")
        
        // Check what's stored in UserDefaults
        let storedDate = WidgetDateState.shared.getStoredDateForTesting()
        print("[WIDGET-DATE-DEBUGGER] Stored date: \(storedDate?.description ?? "nil")")
        
        // Check what currentDate returns
        let currentDate = WidgetDateState.shared.currentDate
        print("[WIDGET-DATE-DEBUGGER] WidgetDateState.currentDate: \(currentDate)")
        
        // Check if it's today
        let isToday = calendar.isDate(currentDate, inSameDayAs: today)
        print("[WIDGET-DATE-DEBUGGER] Is currentDate today? \(isToday)")
        
        // Check if it's yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let isYesterday = calendar.isDate(currentDate, inSameDayAs: yesterday)
            print("[WIDGET-DATE-DEBUGGER] Yesterday: \(yesterday)")
            print("[WIDGET-DATE-DEBUGGER] Is currentDate yesterday? \(isYesterday)")
        }
        
        print("[WIDGET-DATE-DEBUGGER] === END WIDGET DATE DEBUG REPORT ===")
    }
    
    /// Force reset widget date to today
    public static func forceResetToToday() {
        print("[WIDGET-DATE-DEBUGGER] === FORCING WIDGET DATE RESET TO TODAY ===")
        
        WidgetDateState.shared.resetForTesting()
        
        let newCurrentDate = WidgetDateState.shared.currentDate
        print("[WIDGET-DATE-DEBUGGER] After reset - currentDate: \(newCurrentDate)")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let isToday = calendar.isDate(newCurrentDate, inSameDayAs: today)
        print("[WIDGET-DATE-DEBUGGER] Is reset date today? \(isToday)")
        
        print("[WIDGET-DATE-DEBUGGER] === WIDGET DATE RESET COMPLETED ===")
    }
    
    /// Simulate yesterday being stored (for testing the bug)
    public static func simulateYesterdayBug() {
        print("[WIDGET-DATE-DEBUGGER] === SIMULATING YESTERDAY BUG ===")
        
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        WidgetDateState.shared.forceSetDateForTesting(yesterday)
        
        let currentDate = WidgetDateState.shared.currentDate
        print("[WIDGET-DATE-DEBUGGER] After setting yesterday - currentDate: \(currentDate)")
        
        let isYesterday = calendar.isDate(currentDate, inSameDayAs: yesterday)
        print("[WIDGET-DATE-DEBUGGER] Is currentDate yesterday? \(isYesterday)")
        
        print("[WIDGET-DATE-DEBUGGER] === YESTERDAY BUG SIMULATION COMPLETED ===")
    }
}
#endif