import SwiftUI
import RitualistCore
import FactoryKit

struct QuickActionsCard: View {
    let incompleteHabits: [Habit]
    let completedHabits: [Habit]
    let currentSlogan: String?
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let viewingDate: Date // Add viewing date from ViewModel
    let onHabitComplete: (Habit) -> Void
    let getProgressSync: (Habit) -> Double // Sync callback to get current progress from ViewModel
    let onNumericHabitUpdate: (Habit, Double) -> Void // New callback for numeric habit updates
    let onNumericHabitAction: ((Habit) -> Void)? // New callback for numeric habit sheet
    let onDeleteHabitLog: (Habit) -> Void // New callback for deleting habit log
    let getScheduleStatus: (Habit) -> HabitScheduleStatus // New callback for schedule status
    let getValidationMessage: (Habit) async -> String? // New callback for validation message
    let getWeeklyProgress: ((Habit) -> (completed: Int, target: Int))? // For timesPerWeek progress
    
    @State private var animatingHabitId: UUID? = nil
    @State private var glowingHabitId: UUID? = nil
    @State private var showingDeleteAlert = false
    @State private var habitToDelete: Habit?
    @State private var validationMessages: [UUID: String] = [:] // Store validation messages for habits
    
    @Injected(\.hapticFeedbackService) private var hapticService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("⚡")
                        .font(.title2)
                    Text("Quick Log")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(incompleteHabits.count) remaining")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CardDesign.secondaryBackground)
                    )
            }
            
            // Show only incomplete habits - completed habits managed in Today's Progress card
            if !incompleteHabits.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(incompleteHabits, id: \.id) { habit in
                            habitChip(for: habit, isCompleted: false)
                                .opacity(animatingHabitId == habit.id ? 0.0 : 1.0)
                                .animation(.easeOut(duration: 0.3), value: animatingHabitId)
                        }
                    }
                    .padding(.horizontal, 2) // Small padding for shadow
                }
            } else {
                // Perfect day message when no incomplete habits
                VStack(spacing: 12) {
                    Text("🎉")
                        .font(.system(size: 32))
                    
                    Text("All habits completed!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Great work today! Check your progress in Today's card above.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }
        }
        .cardStyle()
        .alert("Delete Log Entry?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                habitToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let habit = habitToDelete {
                    onDeleteHabitLog(habit)
                }
                habitToDelete = nil
            }
        } message: {
            if let habit = habitToDelete {
                Text("This will remove the log entry for \"\(habit.name)\" from today. The habit itself will remain.")
            }
        }
    }
    
    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func habitChip(for habit: Habit, isCompleted: Bool) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = isCompleted || !scheduleStatus.isAvailable
        
        Button {
            if !isCompleted && scheduleStatus.isAvailable {
                if habit.kind == .numeric {
                    // Trigger light haptic for opening numeric sheet
                    hapticService.trigger(.light)
                    onNumericHabitAction?(habit)
                } else {
                    // For binary habits, complete with glow effect and haptic
                    glowingHabitId = habit.id
                    hapticService.triggerCompletion(type: .standard)
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        animatingHabitId = habit.id
                    }
                    
                    Task {
                        // Small delay for glow effect, then complete
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds for glow
                        await MainActor.run {
                            onHabitComplete(habit)
                            animatingHabitId = nil
                            glowingHabitId = nil
                        }
                    }
                }
            } else if !scheduleStatus.isAvailable {
                // Show validation message when user tries to tap disabled habit
                Task {
                    if let message = await getValidationMessage(habit) {
                        validationMessages[habit.id] = message
                        // Clear message after a few seconds
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                        validationMessages[habit.id] = nil
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Circular Progress Indicator with Emoji
                ZStack {
                    // Background circle with habit color at low opacity
                    Circle()
                        .fill(Color(hex: habit.colorHex).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    // Progress border (only for incomplete habits)
                    if !isCompleted {
                        let progressValue: Double = {
                            if habit.kind == .numeric {
                                let currentValue = getProgressSync(habit)
                                let target = habit.dailyTarget ?? 1.0
                                return min(max(currentValue / target, 0.0), 1.0)
                            } else {
                                return 0.0 // Binary incomplete = 0%
                            }
                        }()
                        
                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(Color(hex: habit.colorHex), lineWidth: 3)
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: progressValue)
                    } 
                    // else {
                        // Completed habits show full circle - DISABLED: UX overkill
                        // Circle()
                        //     .trim(from: 0, to: 1.0)
                        //     .stroke(.green, lineWidth: 3)
                        //     .frame(width: 40, height: 40)
                        //     .rotationEffect(.degrees(-90))
                    // }
                    
                    // Emoji
                    Text(habit.emoji ?? "📊")
                        .font(.title3)
                }
                
                // Habit Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isDisabled ? .primary.opacity(0.6) : (isCompleted ? .primary.opacity(0.8) : .primary))
                        .lineLimit(1)
                    
                    // Show validation message if present
                    if let validationMessage = validationMessages[habit.id] {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .lineLimit(2)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else if habit.kind == .numeric, let unitLabel = habit.unitLabel {
                        numericHabitStatusText(habit: habit, unitLabel: unitLabel, isCompleted: isCompleted, isDisabled: isDisabled)
                    } else {
                        habitStatusText(habit: habit, isCompleted: isCompleted, isDisabled: isDisabled, scheduleStatus: scheduleStatus)
                    }
                    
                    // Schedule indicator
                    if !isCompleted {
                        HabitScheduleIndicator.compact(status: scheduleStatus)
                    }
                }
                
                // Complete Icon
                Image(systemName: isCompleted ? "checkmark.circle.fill" : (isDisabled ? "minus.circle" : "plus.circle.fill"))
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : (isDisabled ? .secondary : AppColors.brand))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(chipBackgroundColor(isCompleted: isCompleted, isDisabled: isDisabled))
                    .shadow(color: isCompleted ? .black.opacity(0.08) : .clear, radius: isCompleted ? 4 : 0, x: 0, y: isCompleted ? 2 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(chipBorderColor(isCompleted: isCompleted, isDisabled: isDisabled), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled && !isCompleted ? 0.7 : 1.0)
        .scaleEffect(1.0)
        .completionGlow(isGlowing: glowingHabitId == habit.id)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: incompleteHabits.count)
        .animation(.easeInOut(duration: 0.2), value: validationMessages[habit.id])
        .onLongPressGesture {
            if isCompleted {
                habitToDelete = habit
                showingDeleteAlert = true
            }
        }
    }
    
    
    @ViewBuilder
    private func numericHabitStatusText(habit: Habit, unitLabel: String, isCompleted: Bool, isDisabled: Bool) -> some View {
        if isCompleted {
            let target = Int(habit.dailyTarget ?? 1.0)
            Text("\(target) \(unitLabel) - Completed")
                .font(.caption)
                .foregroundColor(.green)
        } else if isDisabled {
            Text("Not scheduled today")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            let currentValue = getProgressSync(habit)
            let target = habit.dailyTarget ?? 1.0
            let currentInt = Int(currentValue)
            let targetInt = Int(target)
            Text("\(currentInt)/\(targetInt) \(unitLabel)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func habitStatusText(habit: Habit, isCompleted: Bool, isDisabled: Bool, scheduleStatus: HabitScheduleStatus) -> some View {
        if isCompleted {
            // For timesPerWeek habits, show weekly progress even when today is completed
            if case .timesPerWeek = habit.schedule, let getWeeklyProgress = getWeeklyProgress {
                let progress = getWeeklyProgress(habit)
                Text("Today ✓ (\(progress.completed)/\(progress.target) this week)")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        } else if isDisabled {
            Text(scheduleStatus.displayText)
                .font(.caption)
                .foregroundColor(scheduleStatus.color)
        } else {
            // For timesPerWeek habits, show weekly progress
            if case .timesPerWeek = habit.schedule, let getWeeklyProgress = getWeeklyProgress {
                let progress = getWeeklyProgress(habit)
                Text("Tap to complete (\(progress.completed)/\(progress.target) this week)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap to complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func chipBackgroundColor(isCompleted: Bool, isDisabled: Bool) -> Color {
        if isCompleted {
            return Color.green.opacity(0.15)
        } else if isDisabled {
            return CardDesign.secondaryBackground.opacity(0.5)
        } else {
            // Use blue background for remaining (incomplete) habits
            return AppColors.brand.opacity(0.1)
        }
    }
    
    private func chipBorderColor(isCompleted: Bool, isDisabled: Bool) -> Color {
        if isCompleted {
            return Color.green.opacity(0.3)
        } else if isDisabled {
            return Color.secondary.opacity(0.3)
        } else {
            // Use blue border for remaining (incomplete) habits
            return AppColors.brand.opacity(0.2)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // With incomplete and completed habits
        QuickActionsCard(
            incompleteHabits: [
                Habit(
                    id: UUID(),
                    name: "Morning Workout",
                    emoji: "💪",
                    kind: .binary,
                    unitLabel: nil,
                    dailyTarget: 1.0,
                    schedule: .daily,
                    isActive: true,
                    categoryId: nil,
                    suggestionId: nil
                ),
                Habit(
                    id: UUID(),
                    name: "Evening Reading",
                    emoji: "📚",
                    kind: .binary,
                    unitLabel: nil,
                    dailyTarget: 1.0,
                    schedule: .daysOfWeek([2, 4, 6]), // Monday, Wednesday, Friday
                    isActive: true,
                    categoryId: nil,
                    suggestionId: nil
                )
            ],
            completedHabits: [
                Habit(
                    id: UUID(),
                    name: "Water Intake",
                    emoji: "💧",
                    kind: .numeric,
                    unitLabel: "glasses",
                    dailyTarget: 8.0,
                    schedule: .daily,
                    isActive: true,
                    categoryId: nil,
                    suggestionId: nil
                )
            ],
            currentSlogan: "Rise with purpose, rule your day.",
            timeOfDay: .morning,
            completionPercentage: 0.6,
            viewingDate: Date(),
            onHabitComplete: { _ in },
            getProgressSync: { _ in 3.0 }, // Mock progress
            onNumericHabitUpdate: { _, _ in },
            onNumericHabitAction: { _ in },
            onDeleteHabitLog: { _ in },
            getScheduleStatus: { habit in
                // Mock schedule status based on habit schedule
                switch habit.schedule {
                case .daily, .timesPerWeek:
                    return .alwaysScheduled
                case .daysOfWeek:
                    return Calendar.current.component(.weekday, from: Date()) == 2 ? .scheduledToday : .notScheduledToday // Monday
                }
            },
            getValidationMessage: { habit in
                return habit.schedule == .daysOfWeek([2, 4, 6]) && Calendar.current.component(.weekday, from: Date()) != 2 
                    ? "This habit is only scheduled for Monday, Wednesday, and Friday" 
                    : nil
            },
            getWeeklyProgress: { habit in
                if case .timesPerWeek(let target) = habit.schedule {
                    return (completed: 2, target: target) // Mock progress
                }
                return (completed: 0, target: 0)
            }
        )
        
        // Perfect day state
        QuickActionsCard(
            incompleteHabits: [],
            completedHabits: [],
            currentSlogan: "End strong, dream bigger.",
            timeOfDay: .evening,
            completionPercentage: 1.0,
            viewingDate: Date(),
            onHabitComplete: { _ in },
            getProgressSync: { _ in 0.0 },
            onNumericHabitUpdate: { _, _ in },
            onNumericHabitAction: { _ in },
            onDeleteHabitLog: { _ in },
            getScheduleStatus: { _ in .alwaysScheduled },
            getValidationMessage: { _ in nil },
            getWeeklyProgress: { _ in (completed: 0, target: 0) }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
