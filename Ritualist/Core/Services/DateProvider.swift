import Foundation

public protocol DateProvider {
    var now: Date { get }
    func startOfDay(_ date: Date) -> Date
    func weekOfYear(for date: Date, firstWeekday: Int) -> (year: Int, week: Int)
}

public struct SystemDateProvider: DateProvider {
    public init() {}
    public var now: Date { Date() }
    public func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    public func weekOfYear(for date: Date, firstWeekday: Int) -> (year: Int, week: Int) {
        var cal = Calendar.current
        cal.firstWeekday = firstWeekday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }
}
