import SwiftUI
import Foundation
import RitualistCore

// PERFORMANCE: Pre-computed day data - ALL properties calculated ONCE when month changes
private struct DayDisplayData: Identifiable {
    let id: String
    let date: Date
    let dayNumber: Int
    let bgColor: Color
    let textColor: Color
    let hasBorder: Bool
    let opacity: Double
    let isCurrentMonth: Bool
    let row: Int
    let col: Int
}

// PERFORMANCE: Complete rewrite using Canvas for MAXIMUM performance
struct MonthlyCalendarCard: View {
    let monthlyData: [Date: Double]
    let onDateSelect: (Date) -> Void

    @State private var currentDate = Date()
    @State private var displayDays: [DayDisplayData] = []

    private var calendar: Calendar {
        CalendarUtils.currentLocalCalendar
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private var monthString: String {
        Self.monthFormatter.string(from: currentDate)
    }

    private var isViewingCurrentMonth: Bool {
        calendar.isDate(currentDate, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(seasonIcon)
                    .font(.title2)
                Text(monthString)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Navigation
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !isViewingCurrentMonth {
                    Button {
                        currentDate = Date()
                    } label: {
                        Text("Today")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.brand)
                    }
                }

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // PERFORMANCE: Use Canvas for GPU-accelerated rendering - SINGLE draw pass
            GeometryReader { geometry in
                Canvas { context, size in
                    let cellWidth = size.width / 7
                    let cellHeight: CGFloat = 36

                    for dayData in displayDays where dayData.isCurrentMonth {
                        let x = CGFloat(dayData.col) * cellWidth
                        let y = CGFloat(dayData.row) * cellHeight + CGFloat(dayData.row) * 8

                        let rect = CGRect(x: x, y: y, width: cellWidth - 8, height: cellHeight)
                        let center = CGPoint(x: rect.midX, y: rect.midY)
                        let radius: CGFloat = 18

                        // Draw background circle
                        let circlePath = Circle().path(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                        context.fill(circlePath, with: .color(dayData.bgColor.opacity(dayData.opacity)))

                        // Draw border if needed (today)
                        if dayData.hasBorder {
                            context.stroke(circlePath, with: .color(AppColors.brand), lineWidth: 2)
                        }

                        // Draw day number
                        let text = Text("\(dayData.dayNumber)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(dayData.textColor.opacity(dayData.opacity))

                        context.draw(text, at: center, anchor: .center)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    // FIXED: Pass actual canvas width for accurate tap detection
                    handleTap(at: location, canvasWidth: geometry.size.width)
                }
            }
            .frame(height: CGFloat((displayDays.filter { $0.isCurrentMonth }.map { $0.row }.max() ?? 4) + 1) * 44)
        }
        .padding(20)
        .onAppear {
            computeDisplayDays()
        }
        .onChange(of: currentDate) { _, _ in
            computeDisplayDays()
        }
        .onChange(of: monthlyData) { _, _ in
            computeDisplayDays()
        }
    }

    private var seasonIcon: String {
        let month = calendar.component(.month, from: currentDate)
        switch month {
        case 12, 1, 2: return "❄️"
        case 3, 4, 5: return "🌸"
        case 6, 7, 8: return "☀️"
        default: return "🍂"
        }
    }

    private var weekdayHeaders: [String] {
        DateUtils.orderedWeekdaySymbols(style: .veryShort)
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }

    private func getMonthDays(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1)
        else { return [] }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return DateUtils.generateDates(inside: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0), calendar: calendar)
    }

    // PERFORMANCE: Compute ALL display properties ONCE when month changes
    private func computeDisplayDays() {
        let days = getMonthDays(for: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        let today = Date()

        displayDays = days.enumerated().map { index, date in
            let dayNumber = calendar.component(.day, from: date)
            let isCurrentMonth = calendar.component(.month, from: date) == currentMonth
            let isToday = calendar.isDateInToday(date)
            let isFuture = date > today

            let normalizedDate = CalendarUtils.startOfDayUTC(for: date)
            let completion = monthlyData[normalizedDate] ?? 0.0

            // Pre-compute colors
            let bgColor: Color = {
                if isFuture { return CardDesign.secondaryBackground }
                if completion >= 1.0 { return CardDesign.progressGreen }
                if completion >= 0.8 { return CardDesign.progressOrange }
                if completion > 0 { return CardDesign.progressRed.opacity(0.6) }
                return CardDesign.secondaryBackground
            }()

            let textColor: Color = {
                if isToday { return .white }
                if isFuture { return .secondary }
                return completion >= 0.8 ? .white : .primary
            }()

            let opacity: Double = isFuture ? 0.3 : 1.0

            return DayDisplayData(
                id: normalizedDate.timeIntervalSince1970.description,
                date: date,
                dayNumber: dayNumber,
                bgColor: bgColor,
                textColor: textColor,
                hasBorder: isToday,
                opacity: opacity,
                isCurrentMonth: isCurrentMonth,
                row: index / 7,
                col: index % 7
            )
        }
    }

    private func handleTap(at location: CGPoint, canvasWidth: CGFloat) {
        // FIXED: Use actual canvas width instead of screen width
        let cellWidth: CGFloat = canvasWidth / 7
        // FIXED: Account for 8px spacing between rows
        let cellHeight: CGFloat = 36 + 8

        let col = Int(location.x / cellWidth)
        let row = Int(location.y / cellHeight)

        if let dayData = displayDays.first(where: { $0.row == row && $0.col == col && $0.isCurrentMonth }) {
            onDateSelect(dayData.date)
        }
    }
}

#Preview {
    let sampleData: [Date: Double] = {
        var data: [Date: Double] = [:]
        for index in 1...30 {
            let date = CalendarUtils.addDays(-index, to: Date())
            data[CalendarUtils.startOfDayUTC(for: date)] = Double.random(in: 0...1)
        }
        return data
    }()

    MonthlyCalendarCard(
        monthlyData: sampleData,
        onDateSelect: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
