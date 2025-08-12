import SwiftUI
import RitualistCore

struct WeeklyOverviewCard: View {
    let progress: WeeklyProgress?
    
    private var weekdays: [String] {
        DateUtils.orderedWeekdaySymbols(style: .veryShort)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("📅")
                        .font(.title2)
                    Text("This Week")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
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
                        ForEach(0..<7, id: \.self) { dayIndex in
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
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress.currentDayIndex)
                            }
                            .frame(maxWidth: .infinity)
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
}

#Preview {
    VStack(spacing: 20) {
        // With Progress
        WeeklyOverviewCard(progress: WeeklyProgress(
            daysCompleted: [true, true, false, true, false, false, false],
            currentDayIndex: 4
        ))
        
        // Loading State
        WeeklyOverviewCard(progress: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}