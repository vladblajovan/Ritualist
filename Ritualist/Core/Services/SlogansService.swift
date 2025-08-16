import Foundation
import RitualistCore

// MARK: - Slogans Service Implementation

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
        return slogans.randomElement() ?? Strings.Overview.instructions
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

// MARK: - Mock Implementation

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
}
