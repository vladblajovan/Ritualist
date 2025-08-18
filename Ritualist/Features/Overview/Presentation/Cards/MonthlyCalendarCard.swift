import SwiftUI
import Foundation
import RitualistCore

struct MonthlyCalendarCard: View {
    @Binding var isExpanded: Bool
    let monthlyData: [Date: Double] // Date to completion percentage
    let onDateSelect: (Date) -> Void
    
    @State private var currentDate = Date()
    @State private var glowingDate: Date? = nil
    
    private var calendar: Calendar {
        DateUtils.userCalendar()
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private var monthIcon: String {
        let month = calendar.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return "❄️" // Winter
        case 3, 4, 5: return "🌸" // Spring  
        case 6, 7, 8: return "☀️" // Summer
        case 9, 10, 11: return "🍂" // Fall
        default: return "📅"
        }
    }
    
    private var currentViewingIcon: String {
        let month = calendar.component(.month, from: currentDate)
        switch month {
        case 12, 1, 2: return "❄️" // Winter
        case 3, 4, 5: return "🌸" // Spring  
        case 6, 7, 8: return "☀️" // Summer
        case 9, 10, 11: return "🍂" // Fall
        default: return "📅"
        }
    }
    
    private var currentViewingMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private var isViewingCurrentMonth: Bool {
        calendar.isDate(currentDate, equalTo: Date(), toGranularity: .month)
    }
    
    private func goToCurrentMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = Date()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text(isExpanded ? currentViewingIcon : monthIcon)
                        .font(.title2)
                    Text(isExpanded ? currentViewingMonthName : currentMonthName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Collapse" : "Expand")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                // Full Month Calendar
                VStack(spacing: 16) {
                    // Month Navigation
                    HStack {
                        Button {
                            changeMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Back to current month button (only show if not viewing current month)
                        if !isViewingCurrentMonth {
                            Button {
                                goToCurrentMonth()
                            } label: {
                                Text("Back to \(currentMonthName)")
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
                    
                    // Calendar Grid
                    calendarGrid
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))
            } else {
                // Collapsed View - Current Week
                currentWeekView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private var currentWeekView: some View {
        let weekDays = getCurrentWeekDays()
        
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { date in
                    Button {
                        performGlowAndSelect(date: date)
                    } label: {
                        VStack(spacing: 6) {
                            Text(dayFormatter.string(from: date))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            dayIndicator(for: date, size: 28)
                                .overlay(
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(dayTextColor(for: date))
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            let completedDays = weekDays.filter { monthlyData[calendar.startOfDay(for: $0)] ?? 0.0 >= 1.0 }.count
            Text("\(completedDays) of \(weekDays.count) days this week")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var calendarGrid: some View {
        let monthDays = getMonthDays(for: currentDate)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        VStack(spacing: 12) {
            // Weekday Headers - respecting system week start day
            HStack(spacing: 0) {
                ForEach(weekdayHeaders(), id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(monthDays, id: \.self) { date in
                    if calendar.component(.month, from: date) == calendar.component(.month, from: currentDate) {
                        Button {
                            performGlowAndSelect(date: date)
                        } label: {
                            dayIndicator(for: date, size: 36)
                                .overlay(
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(dayTextColor(for: date))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Placeholder for days from previous/next month
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 36)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func dayIndicator(for date: Date, size: CGFloat) -> some View {
        let completionRate = monthlyData[calendar.startOfDay(for: date)] ?? 0.0
        let isToday = calendar.isDateInToday(date)
        let isFutureDate = date > Date()
        
        Circle()
            .fill(dayBackgroundColor(for: date, completionRate: completionRate))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(isToday ? AppColors.brand : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: calendar.isDate(glowingDate ?? Date.distantPast, inSameDayAs: date) ? 
                       AppColors.brand : Color.clear,
                radius: calendar.isDate(glowingDate ?? Date.distantPast, inSameDayAs: date) ? 8 : 0,
                x: 0, y: 0
            )
            .opacity(isFutureDate ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: glowingDate)
    }
    
    private func dayBackgroundColor(for date: Date, completionRate: Double) -> Color {
        let isFutureDate = date > Date()
        
        if isFutureDate {
            return CardDesign.secondaryBackground
        }
        
        if completionRate >= 1.0 {
            return CardDesign.progressGreen  // Only 100% completion is green (completed)
        } else if completionRate >= 0.8 {
            return CardDesign.progressOrange  // 80-99% is orange (almost there)
        } else if completionRate > 0 {
            return CardDesign.progressRed.opacity(0.6)  // Some progress is red
        } else {
            return CardDesign.secondaryBackground  // No progress is gray
        }
    }
    
    private func dayTextColor(for date: Date) -> Color {
        let completionRate = monthlyData[calendar.startOfDay(for: date)] ?? 0.0
        let isToday = calendar.isDateInToday(date)
        let isFutureDate = date > Date()
        
        if isToday {
            return .white  // White text for current day for better visibility
        }
        
        if isFutureDate {
            return .secondary
        }
        
        return completionRate >= 0.8 ? .white : .primary  // White text for orange/green backgrounds
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    private func changeMonth(by value: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
                currentDate = newDate
            }
        }
    }
    
    private func getCurrentWeekDays() -> [Date] {
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private func weekdayHeaders() -> [String] {
        DateUtils.orderedWeekdaySymbols(style: .veryShort)
    }
    
    private func getMonthDays(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1)
        else { return [] }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        
        return DateUtils.generateDates(inside: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0), calendar: calendar)
    }
    
    private func performGlowAndSelect(date: Date) {
        // Start glow effect
        glowingDate = date
        
        // After glow animation completes, trigger date selection
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
            await MainActor.run {
                glowingDate = nil
                onDateSelect(date)
            }
        }
    }
}


#Preview {
    let sampleData: [Date: Double] = {
        let calendar = Calendar.current
        var data: [Date: Double] = [:]
        
        // Generate sample completion data for current month
        for index in 1...30 {
            if let date = calendar.date(byAdding: .day, value: -index, to: Date()) {
                data[calendar.startOfDay(for: date)] = Double.random(in: 0...1)
            }
        }
        
        return data
    }()
    
    VStack(spacing: 20) {
        // Collapsed state
        MonthlyCalendarCard(
            isExpanded: .constant(false),
            monthlyData: sampleData,
            onDateSelect: { _ in }
        )
        
        // Expanded state
        MonthlyCalendarCard(
            isExpanded: .constant(true),
            monthlyData: sampleData,
            onDateSelect: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
