import SwiftUI
import RitualistCore

struct WeeklyOverviewCard: View {
    let progress: WeeklyProgress?
    let onDateSelect: (Date) -> Void
    
    @State private var glowingDate: Date? = nil
    
    private var weekdays: [String] {
        DateUtils.orderedWeekdaySymbols(style: .veryShort)
    }
    
    private var weekInfo: (number: Int, dateRange: String) {
        let today = Date()
        let calendar = DateUtils.userCalendar()
        let weekOfYear = calendar.component(.weekOfYear, from: today)
        
        // Get start and end of current week using calendar
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return (weekOfYear, "")
        }
        
        let startOfWeek = weekInterval.start
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? weekInterval.end
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: startOfWeek)
        let endString = formatter.string(from: endOfWeek)
        
        return (weekOfYear, "\(startString)-\(endString)")
    }
    
    private var currentWeekDates: [Date] {
        let today = Date()
        let calendar = DateUtils.userCalendar()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("📊")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week \(weekInfo.number)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(weekInfo.dateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let progress = progress {
                    Text("\(Int(progress.weeklyCompletionRate * 100))%")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(weeklyColor(for: progress.weeklyCompletionRate))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(weeklyColor(for: progress.weeklyCompletionRate).opacity(0.1))
                        )
                }
            }
            
            if let progress = progress {
                VStack(spacing: 16) {
                    // Week Calendar
                    HStack(spacing: 0) {
                        ForEach(Array(currentWeekDates.enumerated()), id: \.element) { dayIndex, date in
                            Button {
                                performGlowAndSelect(date: date)
                            } label: {
                                VStack(spacing: 8) {
                                    // Day Letter
                                    Text(weekdays[dayIndex])
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    // Day Indicator
                                    ZStack {
                                        Circle()
                                            .fill(dayBackgroundColor(for: dayIndex, progress: progress))
                                            .frame(width: 32, height: 32)
                                        
                                        if progress.daysCompleted.indices.contains(dayIndex) && progress.daysCompleted[dayIndex] {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        } else if dayIndex == progress.currentDayIndex {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    .scaleEffect(dayIndex == progress.currentDayIndex ? 1.1 : 1.0)
                                    .shadow(
                                        color: Calendar.current.isDate(glowingDate ?? Date.distantPast, inSameDayAs: date) ? 
                                               AppColors.brand : Color.clear,
                                        radius: Calendar.current.isDate(glowingDate ?? Date.distantPast, inSameDayAs: date) ? 8 : 0,
                                        x: 0, y: 0
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: glowingDate)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress.currentDayIndex)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Week Summary
                    VStack(spacing: 8) {
                        Text(progress.weekDescription)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(CardDesign.secondaryBackground)
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(weeklyColor(for: progress.weeklyCompletionRate))
                                    .frame(width: geometry.size.width * progress.weeklyCompletionRate, height: 6)
                                    .animation(.easeInOut(duration: 0.8), value: progress.weeklyCompletionRate)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            } else {
                // Loading State
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        ForEach(0..<7) { _ in
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(CardDesign.secondaryBackground)
                                    .frame(width: 12, height: 10)
                                
                                Circle()
                                    .fill(CardDesign.secondaryBackground)
                                    .frame(width: 32, height: 32)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CardDesign.secondaryBackground)
                            .frame(width: 150, height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CardDesign.secondaryBackground)
                            .frame(height: 6)
                    }
                }
                .redacted(reason: .placeholder)
            }
        }
        .cardStyle()
    }
    
    private func dayBackgroundColor(for dayIndex: Int, progress: WeeklyProgress) -> Color {
        if progress.daysCompleted.indices.contains(dayIndex) && progress.daysCompleted[dayIndex] {
            return CardDesign.progressGreen
        } else if dayIndex == progress.currentDayIndex {
            return AppColors.brand
        } else if dayIndex < progress.currentDayIndex {
            return CardDesign.progressRed.opacity(0.3)
        } else {
            return CardDesign.secondaryBackground
        }
    }
    
    private func weeklyColor(for percentage: Double) -> Color {
        if percentage >= 0.8 { return CardDesign.progressGreen }
        else if percentage >= 0.5 { return CardDesign.progressOrange }
        else { return CardDesign.progressRed }
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
    VStack(spacing: 20) {
        // With Progress
        WeeklyOverviewCard(progress: WeeklyProgress(
            daysCompleted: [true, true, false, true, false, false, false],
            currentDayIndex: 4
        ), onDateSelect: { _ in })
        
        // Loading State
        WeeklyOverviewCard(progress: nil, onDateSelect: { _ in })
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
