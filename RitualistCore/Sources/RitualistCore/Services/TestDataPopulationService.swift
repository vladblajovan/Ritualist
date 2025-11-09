//
//  TestDataPopulationService.swift
//  RitualistCore
//
//  Created by Claude on 20.08.2025.
//

import Foundation

// swiftlint:disable large_tuple

#if DEBUG

/// Utility service for test data pattern generation and calculations
/// PHASE 2: Business orchestration moved to PopulateTestDataUseCase
/// This service now contains only utility methods for pattern generation
public protocol TestDataPopulationServiceProtocol {
    /// Get predefined custom category data for test population
    func getCustomCategoryData() -> [(name: String, displayName: String, emoji: String)]

    /// Get predefined custom habit data for test population
    func getCustomHabitData() -> [(name: String, emoji: String, colorHex: String, kind: HabitKind, unitLabel: String?, dailyTarget: Double?, schedule: HabitSchedule)]

    /// Get personality-specific custom category data
    func getPersonalityCategories(for scenario: TestDataScenario) -> [(name: String, displayName: String, emoji: String)]

    /// Get personality-specific custom habit data
    func getPersonalityHabits(for scenario: TestDataScenario) -> [(name: String, emoji: String, colorHex: String, kind: HabitKind, unitLabel: String?, dailyTarget: Double?, schedule: HabitSchedule)]

    /// Generate sophisticated daily completion rate patterns for historical data
    func generateDailyCompletionRates(for dateRange: [Date]) -> [Date: Double]
}

// MARK: - Implementation
public final class TestDataPopulationService: TestDataPopulationServiceProtocol {
    // PHASE 2: Now utility-only service - no business orchestration
    // All business logic moved to PopulateTestDataUseCase
    
    public init() {}
    
    // MARK: - Utility Methods (Data Providers)
    
    public func getCustomCategoryData() -> [(name: String, displayName: String, emoji: String)] {
        return [
            (name: "creative_projects", displayName: "Creative Projects", emoji: "🎨"),
            (name: "home_improvement", displayName: "Home Improvement", emoji: "🏠"),
            (name: "learning_goals", displayName: "Learning Goals", emoji: "🧠")
        ]
    }
    
    public func getCustomHabitData() -> [(name: String, emoji: String, colorHex: String, kind: HabitKind, unitLabel: String?, dailyTarget: Double?, schedule: HabitSchedule)] {
        return [
            (name: "Practice Guitar", emoji: "🎸", colorHex: "#FF6B6B", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
            (name: "Read Pages", emoji: "📚", colorHex: "#45B7D1", kind: .numeric, unitLabel: "pages", dailyTarget: 20.0, schedule: .daily),
            (name: "Home Workouts", emoji: "💪", colorHex: "#4CAF50", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([1, 3, 5]))
        ]
    }

    public func getPersonalityCategories(for scenario: TestDataScenario) -> [(name: String, displayName: String, emoji: String)] {
        switch scenario {
        case .opennessProfile:
            return [
                (name: "creative_projects", displayName: "Creative Projects", emoji: "🎨"),
                (name: "learning_goals", displayName: "Learning Goals", emoji: "🧠"),
                (name: "exploration", displayName: "Exploration", emoji: "🔭")
            ]
        case .conscientiousnessProfile:
            return [
                (name: "goals_planning", displayName: "Goals & Planning", emoji: "🎯"),
                (name: "discipline", displayName: "Discipline", emoji: "⚡"),
                (name: "achievement", displayName: "Achievement", emoji: "🏆")
            ]
        case .extraversionProfile:
            return [
                (name: "social_connections", displayName: "Social Connections", emoji: "🤝"),
                (name: "community", displayName: "Community", emoji: "👥"),
                (name: "networking", displayName: "Networking", emoji: "🌐")
            ]
        case .agreeablenessProfile:
            return [
                (name: "caregiving", displayName: "Caregiving", emoji: "💝"),
                (name: "family_time", displayName: "Family Time", emoji: "👨‍👩‍👧‍👦"),
                (name: "helping_others", displayName: "Helping Others", emoji: "🤲")
            ]
        case .neuroticismProfile:
            return [
                (name: "wellness_attempts", displayName: "Wellness Attempts", emoji: "😰"),
                (name: "self_improvement", displayName: "Self-Improvement", emoji: "📈"),
                (name: "stress_management", displayName: "Stress Management", emoji: "🧘")
            ]
        default:
            return getCustomCategoryData()
        }
    }

    public func getPersonalityHabits(for scenario: TestDataScenario) -> [(name: String, emoji: String, colorHex: String, kind: HabitKind, unitLabel: String?, dailyTarget: Double?, schedule: HabitSchedule)] {
        switch scenario {
        case .opennessProfile:
            return [
                (name: "Try New Restaurant", emoji: "🍽️", colorHex: "#FF6B6B", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([6])),
                (name: "Learn New Language", emoji: "🗣️", colorHex: "#45B7D1", kind: .numeric, unitLabel: "minutes", dailyTarget: 20.0, schedule: .daysOfWeek([1, 3, 5])),
                (name: "Explore New Place", emoji: "🗺️", colorHex: "#4CAF50", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([7])),
                (name: "Creative Writing", emoji: "✍️", colorHex: "#9B59B6", kind: .numeric, unitLabel: "words", dailyTarget: 300.0, schedule: .daysOfWeek([2, 4, 6])),
                (name: "Photography Walk", emoji: "📸", colorHex: "#E67E22", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([7])),
                (name: "Experiment Cooking", emoji: "🧑‍🍳", colorHex: "#F39C12", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([6]))
            ]
        case .conscientiousnessProfile:
            return [
                (name: "Morning Routine", emoji: "☀️", colorHex: "#F39C12", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Daily Planning", emoji: "📋", colorHex: "#3498DB", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Complete Tasks", emoji: "✅", colorHex: "#2ECC71", kind: .numeric, unitLabel: "tasks", dailyTarget: 5.0, schedule: .daily),
                (name: "Evening Review", emoji: "🌙", colorHex: "#9B59B6", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Track Goals", emoji: "📊", colorHex: "#E74C3C", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Organize Workspace", emoji: "🗂️", colorHex: "#95A5A6", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily)
            ]
        case .extraversionProfile:
            return [
                (name: "Call Friends", emoji: "📞", colorHex: "#3498DB", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([1, 3, 5])),
                (name: "Meet New People", emoji: "👋", colorHex: "#F39C12", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([6, 7])),
                (name: "Social Activity", emoji: "🎉", colorHex: "#E74C3C", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([5, 6])),
                (name: "Team Collaboration", emoji: "👥", colorHex: "#9B59B6", kind: .numeric, unitLabel: "hours", dailyTarget: 2.0, schedule: .daysOfWeek([1, 2, 3, 4, 5])),
                (name: "Community Event", emoji: "🌐", colorHex: "#2ECC71", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([7])),
                (name: "Visit Family", emoji: "🏠", colorHex: "#E67E22", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([7]))
            ]
        case .agreeablenessProfile:
            return [
                (name: "Help Someone", emoji: "🤝", colorHex: "#2ECC71", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Family Time", emoji: "👨‍👩‍👧", colorHex: "#E74C3C", kind: .numeric, unitLabel: "hours", dailyTarget: 2.0, schedule: .daily),
                (name: "Volunteer Work", emoji: "🤲", colorHex: "#9B59B6", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([6])),
                (name: "Care for Pets", emoji: "🐕", colorHex: "#F39C12", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Support Friend", emoji: "💬", colorHex: "#3498DB", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([1, 3, 5])),
                (name: "Acts of Kindness", emoji: "💝", colorHex: "#E91E63", kind: .numeric, unitLabel: "acts", dailyTarget: 3.0, schedule: .daily)
            ]
        case .neuroticismProfile:
            return [
                (name: "Stress Management", emoji: "😰", colorHex: "#E74C3C", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Anxiety Journal", emoji: "📝", colorHex: "#9B59B6", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Mood Tracking", emoji: "😔", colorHex: "#95A5A6", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daily),
                (name: "Self-Care Attempt", emoji: "🛁", colorHex: "#3498DB", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([1, 4])),
                (name: "Therapy Exercises", emoji: "🧠", colorHex: "#2ECC71", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([2, 5])),
                (name: "Coping Strategies", emoji: "🎯", colorHex: "#F39C12", kind: .binary, unitLabel: nil, dailyTarget: nil, schedule: .daysOfWeek([3, 6]))
            ]
        default:
            return getCustomHabitData()
        }
    }
    
    public func generateDailyCompletionRates(for dateRange: [Date]) -> [Date: Double] {
        var dailyCompletionRates: [Date: Double] = [:]
        let today = CalendarUtils.startOfDayUTC(for: Date())
        
        let monthlyBaselines = generateMonthlyPerformanceBaselines()
        let weeklyVariations = generateWeeklyVariations(for: dateRange)
        let specialEvents = generateLifeEvents(for: dateRange)
        
        for (dayIndex, date) in dateRange.enumerated() {
            let isToday = CalendarUtils.isSameDay(date, today)
            
            if isToday {
                dailyCompletionRates[date] = 0.85 // 85% completion for today (3 habits remaining)
            } else {
                let completionRate = calculateDailyCompletionRate(
                    date: date,
                    dayIndex: dayIndex,
                    monthlyBaselines: monthlyBaselines,
                    weeklyVariations: weeklyVariations,
                    specialEvents: specialEvents,
                )
                dailyCompletionRates[date] = completionRate
            }
        }
        
        return dailyCompletionRates
    }
    
    // MARK: - Pattern Generation Utilities (Private)
    
    /// Represents different life events that affect habit completion
    private enum LifeEvent {
        case vacation(intensity: Double)    // 0.0 = total break, 1.0 = perfect vacation habits
        case sickness(severity: Double)     // 0.0 = bedridden, 1.0 = mild cold
        case stressfulPeriod(impact: Double) // 0.0 = overwhelming, 1.0 = slightly busy
        case motivationBoost(boost: Double)  // 1.0 = normal, 2.0 = super motivated
        case perfectStreak(length: Int)      // Consecutive days of 100% completion
        case recovery(gradual: Bool)         // Post-disruption recovery period
    }
    
    /// Monthly performance baselines representing habit formation journey
    private struct MonthlyBaseline {
        let baselineRate: Double        // Core performance level
        let consistency: Double         // How stable the performance is (lower = more variation)
        let trendDirection: Double      // Positive = improving, negative = declining
        let description: String         // For debugging/understanding
    }
    
    /// Weekly variations within months
    private struct WeeklyPattern {
        let weekStartRate: Double       // Monday energy
        let midWeekRate: Double        // Wednesday productivity
        let weekendRate: Double        // Saturday/Sunday completion
        let fatiguePattern: Double     // How much performance drops through week
    }
    
    private func generateMonthlyPerformanceBaselines() -> [MonthlyBaseline] {
        return [
            // Month 1 (90-60 days ago): Enthusiastic start, then reality hits
            MonthlyBaseline(
                baselineRate: 0.72,
                consistency: 0.6,  // High variation - learning period
                trendDirection: -0.1,  // Slight decline as novelty wears off
                description: "Initial enthusiasm with reality check"
            ),
            
            // Month 2 (60-30 days ago): The struggle period, building discipline
            MonthlyBaseline(
                baselineRate: 0.58,
                consistency: 0.75, // More consistent, but lower overall
                trendDirection: 0.05,  // Gradual improvement
                description: "Discipline building phase"
            ),
            
            // Month 3 (30-0 days ago): Habit formation success, more stable
            MonthlyBaseline(
                baselineRate: 0.78,
                consistency: 0.85, // Much more consistent
                trendDirection: 0.08,  // Clear improvement trend
                description: "Habit formation mastery"
            )
        ]
    }
    
    private func generateWeeklyVariations(for dateRange: [Date]) -> [Date: WeeklyPattern] {
        var patterns: [Date: WeeklyPattern] = [:]
        
        for date in dateRange {
            // Create realistic weekly patterns
            let pattern = WeeklyPattern(
                weekStartRate: Double.random(in: 0.8...0.95),    // Strong Monday motivation
                midWeekRate: Double.random(in: 0.7...0.85),      // Steady midweek
                weekendRate: Double.random(in: 0.5...0.9),       // Variable weekends
                fatiguePattern: Double.random(in: 0.85...0.95)   // How much energy drops
            )
            
            patterns[date] = pattern
        }
        
        return patterns
    }
    
    private func generateLifeEvents(for dateRange: [Date]) -> [Date: LifeEvent] {
        var events: [Date: LifeEvent] = [:]
        let totalDays = dateRange.count
        
        // Add 2-3 zero completion days (life happens!)
        let zeroCompletionDays = Set((0..<3).compactMap { _ in
            dateRange.randomElement()
        })
        
        for date in zeroCompletionDays {
            events[date] = .sickness(severity: 0.0)
        }
        
        // Add vacation period (5-7 days, lower completion but not zero)
        if let vacationStart = dateRange.dropFirst(totalDays/3).dropLast(totalDays/3).randomElement() {
            for dayOffset in 0..<Int.random(in: 5...7) {
                let vacationDay = CalendarUtils.addDays(dayOffset, to: vacationStart)
                if dateRange.contains(vacationDay) {
                    events[vacationDay] = .vacation(intensity: Double.random(in: 0.2...0.5))
                }
            }
        }
        
        // Add motivation boost period (3-5 days of excellent performance)
        if let boostStart = dateRange.dropFirst(totalDays/2).randomElement() {
            for dayOffset in 0..<Int.random(in: 3...5) {
                let boostDay = CalendarUtils.addDays(dayOffset, to: boostStart)
                if dateRange.contains(boostDay) {
                    events[boostDay] = .motivationBoost(boost: Double.random(in: 1.3...1.5))
                }
            }
        }
        
        // Add stressful period (4-6 days of reduced performance)
        if let stressStart = dateRange.dropFirst(totalDays/4).dropLast(totalDays/2).randomElement() {
            for dayOffset in 0..<Int.random(in: 4...6) {
                let stressDay = CalendarUtils.addDays(dayOffset, to: stressStart)
                if dateRange.contains(stressDay) {
                    events[stressDay] = .stressfulPeriod(impact: Double.random(in: 0.3...0.6))
                }
            }
        }
        
        // Add perfect streak (7-10 days of 100% completion) 
        if let streakStart = dateRange.dropFirst(totalDays*2/3).randomElement() {
            let streakLength = Int.random(in: 7...10)
            for dayOffset in 0..<streakLength {
                let streakDay = CalendarUtils.addDays(dayOffset, to: streakStart)
                if dateRange.contains(streakDay) {
                    events[streakDay] = .perfectStreak(length: streakLength)
                }
            }
        }
        
        return events
    }
    
    private func calculateDailyCompletionRate(
        date: Date,
        dayIndex: Int,
        monthlyBaselines: [MonthlyBaseline],
        weeklyVariations: [Date: WeeklyPattern],
        specialEvents: [Date: LifeEvent]
    ) -> Double {
        
        // Determine which month we're in (0 = oldest month, 2 = most recent)
        let monthIndex = min(2, dayIndex / 30)
        let baseline = monthlyBaselines[monthIndex]
        
        // Start with monthly baseline
        var completionRate = baseline.baselineRate
        
        // Apply trend (gradual improvement/decline over time)
        let progressInMonth = Double(dayIndex % 30) / 30.0
        completionRate += baseline.trendDirection * progressInMonth
        
        // Apply weekly pattern variations
        if let weeklyPattern = weeklyVariations[date] {
            let weekday = CalendarUtils.weekdayComponentUTC(from: date)
            let weekdayMultiplier: Double
            
            switch weekday {
            case 2, 3: // Monday, Tuesday - high energy
                weekdayMultiplier = weeklyPattern.weekStartRate
            case 4, 5: // Wednesday, Thursday - steady
                weekdayMultiplier = weeklyPattern.midWeekRate * weeklyPattern.fatiguePattern
            case 6, 7, 1: // Friday, Saturday, Sunday - variable
                weekdayMultiplier = weeklyPattern.weekendRate
            default:
                weekdayMultiplier = 0.75
            }
            
            completionRate *= weekdayMultiplier
        }
        
        // Apply special events (this can override everything else)
        if let event = specialEvents[date] {
            switch event {
            case .vacation(let intensity):
                completionRate = intensity
            case .sickness(let severity):
                completionRate = severity  // Can be 0.0 for complete zero days
            case .stressfulPeriod(let impact):
                completionRate *= impact
            case .motivationBoost(let boost):
                completionRate = min(1.0, completionRate * boost)
            case .perfectStreak(_):
                completionRate = 1.0  // Perfect completion
            case .recovery(let gradual):
                if gradual {
                    completionRate *= Double.random(in: 0.6...0.9)  // Gradual recovery
                } else {
                    completionRate *= Double.random(in: 0.4...0.7)  // Slower recovery
                }
            }
        }
        
        // Add natural daily variation based on consistency level
        let variationRange = (1.0 - baseline.consistency) * 0.3 // Up to 30% variation for low consistency
        let dailyVariation = Double.random(in: -variationRange...variationRange)
        completionRate += dailyVariation
        
        // Ensure completion rate stays within realistic bounds
        return max(0.0, min(1.0, completionRate))
    }
}

#endif