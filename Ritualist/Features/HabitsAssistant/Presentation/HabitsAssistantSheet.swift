//
//  HabitsAssistantSheet.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import SwiftUI
import RitualistCore

public struct HabitsAssistantSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    private let vm: HabitsAssistantViewModel
    private let existingHabits: [Habit]
    private let onHabitCreate: (HabitSuggestion) async -> CreateHabitFromSuggestionResult
    private let onHabitRemove: (UUID) async -> Bool
    private let onShowPaywall: () -> Void
    
    public init(vm: HabitsAssistantViewModel,
                existingHabits: [Habit] = [],
                onHabitCreate: @escaping (HabitSuggestion) async -> CreateHabitFromSuggestionResult,
                onHabitRemove: @escaping (UUID) async -> Bool,
                onShowPaywall: @escaping () -> Void) {
        self.vm = vm
        self.existingHabits = existingHabits
        self.onHabitCreate = onHabitCreate
        self.onHabitRemove = onHabitRemove
        self.onShowPaywall = onShowPaywall
    }
    
    public var body: some View {
        NavigationView {
            HabitsAssistantView(
                vm: vm,
                existingHabits: existingHabits,
                onHabitCreate: onHabitCreate,
                onHabitRemove: onHabitRemove,
                onShowPaywall: { 
                    // Dismiss sheet first, then show paywall
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onShowPaywall()
                    }
                }
            )
            .navigationTitle("Habit Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

