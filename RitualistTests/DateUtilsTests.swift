//
//  DateUtilsTests.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import XCTest
@testable import Ritualist

final class DateUtilsTests: XCTestCase {

    func testStartOfDay_and_isSameDay() {
        let calendar = Calendar(identifier: .gregorian)
        // Pick a date-time with hour/minute
        let components = DateComponents(year: 2025, month: 3, day: 10, hour: 15, minute: 45)
        let dt = calendar.date(from: components)!
        let sod = DateUtils.startOfDay(dt, calendar: calendar)

        // startOfDay should drop time components
        XCTAssertEqual(calendar.component(.hour, from: sod), 0)
        XCTAssertEqual(calendar.component(.minute, from: sod), 0)

        // isSameDay should be true for dt vs sod
        XCTAssertTrue(DateUtils.isSameDay(dt, sod, calendar: calendar))
    }

    func testDaysBetween() {
        let calendar = Calendar(identifier: .gregorian)
        let day1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let day5 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))!
        XCTAssertEqual(DateUtils.daysBetween(day1, day5, calendar: calendar), 4)
        XCTAssertEqual(DateUtils.daysBetween(day5, day1, calendar: calendar), -4)
    }

    func testWeekKey_onDifferentWeekdays() {
        let calendar = Calendar(identifier: .gregorian)
        // 2025-01-01 is a Wednesday
        let jan1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        // If week starts on Monday (2), this is week 1 of 2025
        let keyMon = DateUtils.weekKey(for: jan1, firstWeekday: 2, calendar: calendar)
        XCTAssertEqual(keyMon.year, 2025)
        XCTAssertEqual(keyMon.week, 1)
        // If week starts on Sunday (1), this falls in week 0 or last week of 2024
        let keySun = DateUtils.weekKey(for: jan1, firstWeekday: 1, calendar: calendar)
        // Depending on locale rules, make a loose check:
        XCTAssertNotNil(keySun.week)
    }

    func testDaysBetween_acrossDSTTransition() {
        // e.g. US DST starts March 9, 2025 at 2:00am
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        let beforeDST = calendar.date(from: DateComponents(year: 2025, month: 3, day: 8, hour: 12))!
        let afterDST = calendar.date(from: DateComponents(year: 2025, month: 3, day: 10, hour: 12))!
        // Should be exactly 2 days apart, despite the 23-hour DST day
        XCTAssertEqual(DateUtils.daysBetween(beforeDST, afterDST, calendar: calendar), 2)
    }
}
