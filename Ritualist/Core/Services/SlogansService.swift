import Foundation

// MARK: - Time of Day

public enum TimeOfDay: CaseIterable {
    case morning    // Until 11:00
    case noon       // Between 11:00 and 16:00
    case evening    // After 16:00
}

// MARK: - Slogans Service Protocol

public protocol SlogansServiceProtocol {
    /// Get a random slogan for the current time of day
    func getCurrentSlogan() -> String
    
    /// Get a random slogan for a specific time of day
    func getSlogan(for timeOfDay: TimeOfDay) -> String
    
    /// Get the current time of day based on current time
    func getCurrentTimeOfDay() -> TimeOfDay
    
    /// Get the current time of day based on a specific date
    func getTimeOfDay(for date: Date) -> TimeOfDay
}

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
        let timeOfDay = getCurrentTimeOfDay()
        return getSlogan(for: timeOfDay)
    }
    
    public func getSlogan(for timeOfDay: TimeOfDay) -> String {
        let slogans = getSlogans(for: timeOfDay)
        return slogans.randomElement() ?? Strings.Overview.instructions
    }
    
    public func getCurrentTimeOfDay() -> TimeOfDay {
        let currentDate = DateUtils.now
        return getTimeOfDay(for: currentDate)
    }
    
    public func getTimeOfDay(for date: Date) -> TimeOfDay {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 0..<11:
            return .morning
        case 11..<16:
            return .noon
        default:
            return .evening
        }
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
    
    public func getCurrentTimeOfDay() -> TimeOfDay {
        fixedTimeOfDay
    }
    
    public func getTimeOfDay(for date: Date) -> TimeOfDay {
        fixedTimeOfDay
    }
}
