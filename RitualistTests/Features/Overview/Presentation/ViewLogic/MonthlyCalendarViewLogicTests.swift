import Testing
import SwiftUI
@testable import RitualistCore

/// Tests for MonthlyCalendarViewLogic - demonstrates testable view logic pattern
@Suite("MonthlyCalendarViewLogic Tests")
struct MonthlyCalendarViewLogicTests {

    let calendar = CalendarUtils.currentLocalCalendar
    let today = Date()
    let yesterday: Date
    let tomorrow: Date
    let currentMonth: Int

    init() {
        yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        currentMonth = calendar.component(.month, from: today)
    }

    // MARK: - Background Color Tests

    @Test("Background color for high completion (100%)")
    func backgroundColorHighCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 1.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressGreen)
    }

    @Test("Background color for high-medium completion (85%) - should be green")
    func backgroundColorHighMediumCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.85,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressGreen)
    }

    @Test("Background color for medium completion (65%) - should be orange")
    func backgroundColorMediumCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.65,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressOrange)
    }

    @Test("Background color at 80% boundary - should be green")
    func backgroundColorAt80Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.8,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressGreen)
    }

    @Test("Background color at 50% boundary - should be orange")
    func backgroundColorAt50Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressOrange)
    }

    @Test("Background color just below 50% (49%) - should be red")
    func backgroundColorBelow50Percent() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.49,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressRed.opacity(0.6))
    }

    @Test("Background color for low completion (30%)")
    func backgroundColorLowCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.3,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.progressRed.opacity(0.6))
    }

    @Test("Background color for no completion (0%)")
    func backgroundColorNoCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.secondaryBackground)
    }

    @Test("Background color for future date")
    func backgroundColorFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.backgroundColor(for: context)
        #expect(color == CardDesign.secondaryBackground)
    }

    // MARK: - Text Color Tests

    @Test("Text color for today with high progress (readable white on colored background)")
    func textColorTodayHighProgress() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.9,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .white, "High progress today should use white text")
    }

    @Test("Text color for today with no progress (readable dark on gray background)")
    func textColorTodayNoProgress() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .primary, "No progress today should use dark text for contrast")
    }

    @Test("Text color for today with low progress (readable dark on light background)")
    func textColorTodayLowProgress() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .primary, "Low progress today should use dark text for contrast")
    }

    @Test("Text color for past date with high completion")
    func textColorPastHighCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.9,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .white)
    }

    @Test("Text color for past date with no completion")
    func textColorPastNoCompletion() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .primary)
    }

    @Test("Text color for future date")
    func textColorFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let color = MonthlyCalendarViewLogic.textColor(for: context)
        #expect(color == .secondary)
    }

    // MARK: - Opacity Tests

    @Test("Opacity for past date")
    func opacityPastDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let opacity = MonthlyCalendarViewLogic.opacity(for: context)
        #expect(opacity == 1.0)
    }

    @Test("Opacity for today")
    func opacityToday() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let opacity = MonthlyCalendarViewLogic.opacity(for: context)
        #expect(opacity == 1.0)
    }

    @Test("Opacity for future date")
    func opacityFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let opacity = MonthlyCalendarViewLogic.opacity(for: context)
        #expect(opacity == 0.3, "Future dates should have reduced opacity")
    }

    // MARK: - Border Tests

    @Test("Border shown for today")
    func borderShownForToday() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.5,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let hasBorder = MonthlyCalendarViewLogic.shouldShowBorder(for: context)
        #expect(hasBorder == true)
    }

    @Test("Border not shown for past date")
    func borderNotShownForPastDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 1.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let hasBorder = MonthlyCalendarViewLogic.shouldShowBorder(for: context)
        #expect(hasBorder == false)
    }

    @Test("Border not shown for future date")
    func borderNotShownForFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        let hasBorder = MonthlyCalendarViewLogic.shouldShowBorder(for: context)
        #expect(hasBorder == false)
    }

    // MARK: - Context Computed Properties Tests

    @Test("Context correctly identifies today")
    func contextIdentifiesToday() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: today,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        #expect(context.isToday == true)
        #expect(context.isFuture == false)
    }

    @Test("Context correctly identifies future date")
    func contextIdentifiesFutureDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: tomorrow,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        #expect(context.isToday == false)
        #expect(context.isFuture == true)
    }

    @Test("Context correctly identifies past date")
    func contextIdentifiesPastDate() {
        let context = MonthlyCalendarViewLogic.DayContext(
            date: yesterday,
            completion: 0.0,
            today: today,
            currentMonth: currentMonth,
            calendar: calendar
        )

        #expect(context.isToday == false)
        #expect(context.isFuture == false)
    }
}
