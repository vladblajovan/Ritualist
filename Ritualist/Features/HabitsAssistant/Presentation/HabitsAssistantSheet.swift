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
        NavigationStack {
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
        .deviceAwareSheetSizing(
            compactMultiplier: (min: 0.88, ideal: 0.97, max: 1.0),
            regularMultiplier: (min: 0.80, ideal: 0.93, max: 1.0),
            largeMultiplier: (min: 0.72, ideal: 0.83, max: 0.94)
        )
    }
}

