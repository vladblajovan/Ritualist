//
//  SlogansServiceProtocol.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

public protocol SlogansServiceProtocol {
    /// Get a random slogan for the current time of day
    func getCurrentSlogan() -> String

    /// Get a random slogan for a specific time of day
    func getSlogan(for timeOfDay: TimeOfDay) -> String

    /// Get multiple unique slogans for a specific time of day
    /// - Parameters:
    ///   - count: Number of unique slogans to return
    ///   - timeOfDay: The time of day to get slogans for
    /// - Returns: Array of unique slogans (may be fewer than requested if not enough available)
    func getUniqueSlogans(count: Int, for timeOfDay: TimeOfDay) -> [String]
}

// MARK: - Implementations

/// Default implementation of SlogansService
public final class SlogansService: SlogansServiceProtocol {
    
    // MARK: - Slogans Data
    
    private let morningSlogans = [
        "Rise with purpose, rule your day.",
        "Morning rituals, unstoppable momentum.",
        "Start strong, finish stronger.",
        "Your morning sets the entire tone.",
        "Dawn your power, own your day.",
        "First light, first win.",
        "Morning magic starts with you.",
        "Sunrise your potential.",
        "Begin brilliantly, become legendary.",
        "Morning rituals, evening victories."
    ]
    
    private let noonSlogans = [
        "Midday momentum, unstoppable force.",
        "Noon reset, afternoon conquest.",
        "Peak hours, peak performance.",
        "Midday rituals, sustained success.",
        "Power through, push forward.",
        "Noon fuel for evening triumph.",
        "Midday mastery, all-day energy.",
        "Stay consistent, stay winning.",
        "Noon tune-up, afternoon takeoff.",
        "Midday rituals, maximum impact."
    ]
    
    private let eveningSlogans = [
        "End strong, dream bigger.",
        "Evening rituals, tomorrow's foundation.",
        "Sunset your day, sunrise your future.",
        "Close with purpose, wake with power.",
        "Evening reflection, morning perfection.",
        "Wind down, level up.",
        "Nightfall rituals, daybreak victories.",
        "Rest with intention, rise with ambition.",
        "Evening calm, morning storm.",
        "Close the loop, open tomorrow."
    ]
    
    public init() {}
    
    // MARK: - Public Methods
    
    public func getCurrentSlogan() -> String {
        let timeOfDay = TimeOfDay.current()
        return getSlogan(for: timeOfDay)
    }
    
    public func getSlogan(for timeOfDay: TimeOfDay) -> String {
        let slogans = getSlogans(for: timeOfDay)
        return slogans.randomElement() ?? "Build your rituals, rule your life."
    }

    public func getUniqueSlogans(count: Int, for timeOfDay: TimeOfDay) -> [String] {
        let allSlogans = getSlogans(for: timeOfDay)
        let shuffled = allSlogans.shuffled()
        return Array(shuffled.prefix(count))
    }

    // MARK: - Private Methods
    
    private func getSlogans(for timeOfDay: TimeOfDay) -> [String] {
        switch timeOfDay {
        case .morning:
            return morningSlogans
        case .noon:
            return noonSlogans
        case .evening:
            return eveningSlogans
        }
    }
}

/// Mock implementation for testing
public final class MockSlogansService: SlogansServiceProtocol {
    
    private let fixedSlogan: String
    private let fixedTimeOfDay: TimeOfDay
    
    public init(fixedSlogan: String = "Mock slogan for testing", fixedTimeOfDay: TimeOfDay = .morning) {
        self.fixedSlogan = fixedSlogan
        self.fixedTimeOfDay = fixedTimeOfDay
    }
    
    public func getCurrentSlogan() -> String {
        fixedSlogan
    }

    public func getSlogan(for timeOfDay: TimeOfDay) -> String {
        fixedSlogan
    }

    public func getUniqueSlogans(count: Int, for timeOfDay: TimeOfDay) -> [String] {
        // For mock, return the same fixed slogan repeated (or unique versions for testing)
        return (0..<count).map { "\(fixedSlogan) \($0 + 1)" }
    }
}
