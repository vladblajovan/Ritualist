import SwiftUI

struct TodaysSummaryCard: View {
    let summary: TodaysSummary?
    let onQuickAction: (Habit) -> Void
    
    init(summary: TodaysSummary?, onQuickAction: @escaping (Habit) -> Void) {
        self.summary = summary
        self.onQuickAction = onQuickAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card Header
            HStack {
                Text("🎯 Today's Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if let summary = summary {
                // Main Progress Section
                HStack(spacing: 32) {
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(CardDesign.secondaryBackground, lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0.0, to: summary.completionPercentage)
                            .stroke(progressColor(for: summary.completionPercentage), lineWidth: 8)
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: summary.completionPercentage)
                        
                        Text("\(Int(summary.completionPercentage * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(progressColor(for: summary.completionPercentage))
                    }
                    
                    // Progress Details
                    VStack(alignment: .leading, spacing: 12) {
                        // Habit Progress Dots - Flexible Grid for multiple lines
                        LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 14, maximum: 18), spacing: 10), count: 12), spacing: 8) {
                            ForEach(0..<summary.totalHabits, id: \.self) { index in
                                Circle()
                                    .fill(index < summary.completedHabits ? 
                                          progressColor(for: summary.completionPercentage) : 
                                          CardDesign.secondaryBackground)
                                    .frame(width: 14, height: 14)
                                    .scaleEffect(index < summary.completedHabits ? 1.0 : 0.85)
                                    .shadow(color: index < summary.completedHabits ? 
                                           progressColor(for: summary.completionPercentage).opacity(0.3) : 
                                           Color.clear, 
                                           radius: 2, x: 0, y: 1)
                                    .overlay(
                                        Circle()
                                            .stroke(index < summary.completedHabits ? 
                                                   progressColor(for: summary.completionPercentage).opacity(0.2) :
                                                   Color.clear, 
                                                   lineWidth: 0.5)
                                    )
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(Double(index) * 0.1), value: summary.completedHabits)
                            }
                        }
                        
                        // Habit Count Text
                        Text("\(summary.completedHabits)/\(summary.totalHabits) habits completed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Motivational Message
                        Text(summary.motivationalMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                // Quick Action for Next Habit (if incomplete habits exist)
                if !summary.incompleteHabits.isEmpty, let nextHabit = summary.incompleteHabits.first {
                    quickActionButton(for: nextHabit)
                }
                
            } else {
                // Loading State
                loadingView
            }
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private func quickActionButton(for habit: Habit) -> some View {
        Button {
            onQuickAction(habit)
        } label: {
            HStack(spacing: 12) {
                Text(habit.emoji ?? "📊")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next: \(habit.name)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Tap to complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.brand)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(CardDesign.secondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: summary?.completedHabits)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        HStack(spacing: 24) {
            // Loading Ring
            Circle()
                .stroke(CardDesign.secondaryBackground, lineWidth: 8)
                .frame(width: 80, height: 80)
                .overlay(
                    ProgressView()
                        .scaleEffect(0.8)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(CardDesign.secondaryBackground)
                    .frame(width: 120, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(CardDesign.secondaryBackground)
                    .frame(width: 80, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(CardDesign.secondaryBackground)
                    .frame(width: 160, height: 12)
            }
            
            Spacer()
        }
        .redacted(reason: .placeholder)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 0.8 {
            return CardDesign.progressGreen
        } else if percentage >= 0.5 {
            return CardDesign.progressOrange
        } else {
            return CardDesign.progressRed
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Completed state
        TodaysSummaryCard(
            summary: TodaysSummary(
                completedHabits: 4,
                totalHabits: 5,
                incompleteHabits: [
                    Habit(
                        id: UUID(),
                        name: "Evening Reading",
                        emoji: "📚",
                        kind: .binary,
                        unitLabel: nil,
                        dailyTarget: 1.0,
                        schedule: .daily,
                        isActive: true,
                        categoryId: nil,
                        suggestionId: nil
                    )
                ]
            ),
            onQuickAction: { _ in }
        )
        
        // Perfect day state
        TodaysSummaryCard(
            summary: TodaysSummary(
                completedHabits: 5,
                totalHabits: 5,
                incompleteHabits: []
            ),
            onQuickAction: { _ in }
        )
        
        // Loading state
        TodaysSummaryCard(
            summary: nil,
            onQuickAction: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
