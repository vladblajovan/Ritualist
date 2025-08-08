import SwiftUI

// Shared view modifier for handling numeric habit sheet presentation
public struct NumericHabitSheetHandler: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedHabit: Habit?
    
    let viewingDate: Date
    let getCurrentProgress: ((Habit) -> Double)?
    let onNumericHabitUpdate: ((Habit, Double) async -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if let habit = selectedHabit, habit.kind == .numeric {
                    NumericHabitLogSheetDirect(
                        habit: habit,
                        viewingDate: viewingDate,
                        getCurrentProgress: getCurrentProgress,
                        onSave: { newValue in
                            Task {
                                await onNumericHabitUpdate?(habit, newValue)
                            }
                        },
                        onCancel: {
                            // Sheet dismisses automatically
                        }
                    )
                }
            }
    }
}

// Extension for easier usage
public extension View {
    func numericHabitSheet(
        isPresented: Binding<Bool>,
        selectedHabit: Binding<Habit?>,
        viewingDate: Date,
        getCurrentProgress: ((Habit) -> Double)? = nil,
        onNumericHabitUpdate: ((Habit, Double) async -> Void)? = nil
    ) -> some View {
        modifier(NumericHabitSheetHandler(
            isPresented: isPresented,
            selectedHabit: selectedHabit,
            viewingDate: viewingDate,
            getCurrentProgress: getCurrentProgress,
            onNumericHabitUpdate: onNumericHabitUpdate
        ))
    }
}

// Shared habit action handler
public struct HabitActionHandler {
    let viewingDate: Date
    let getCurrentProgress: ((Habit) -> Double)?
    let onQuickAction: (Habit) -> Void
    let onNumericSheet: (Habit) -> Void
    
    public func handleHabitTap(_ habit: Habit) {
        if habit.kind == .numeric {
            onNumericSheet(habit)
        } else {
            onQuickAction(habit)
        }
    }
}