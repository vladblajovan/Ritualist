//
//  HabitAssistantSheet.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import SwiftUI

public struct HabitAssistantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: HabitSuggestionCategory = .health
    @State private var addedHabits: Set<String> = []
    @State private var createdHabits: [String: UUID] = [:] // Maps suggestion ID to habit ID
    @State private var isCreatingHabit = false
    @State private var isDeletingHabit = false
    
    private let suggestionsService: HabitSuggestionsService
    private let existingHabits: [Habit]
    private let onHabitCreate: (HabitSuggestion) async -> CreateHabitFromSuggestionResult
    private let onHabitRemove: (UUID) async -> Bool
    private let onShowPaywall: () -> Void
    private let userActionTracker: UserActionTracker?
    
    public init(suggestionsService: HabitSuggestionsService,
                existingHabits: [Habit] = [],
                onHabitCreate: @escaping (HabitSuggestion) async -> CreateHabitFromSuggestionResult,
                onHabitRemove: @escaping (UUID) async -> Bool,
                onShowPaywall: @escaping () -> Void,
                userActionTracker: UserActionTracker? = nil) {
        self.suggestionsService = suggestionsService
        self.existingHabits = existingHabits
        self.onHabitCreate = onHabitCreate
        self.onHabitRemove = onHabitRemove
        self.onShowPaywall = onShowPaywall
        self.userActionTracker = userActionTracker
        // Pre-populate addedHabits and createdHabits based on existing habits
        let (addedSuggestions, habitMappings) = Self.mapExistingHabitsToSuggestions(existingHabits)
        self._addedHabits = State(initialValue: addedSuggestions)
        self._createdHabits = State(initialValue: habitMappings)
    }
    
    private var suggestions: [HabitSuggestion] {
        suggestionsService.getSuggestions(for: selectedCategory)
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category selector (sticky at top for easy filtering)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.medium) {
                        ForEach(HabitSuggestionCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                                userActionTracker?.track(.habitsAssistantCategorySelected(category: categoryName(for: category)))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .mask(
                    // Fade out edges when content overflows
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 0.95),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.bottom, Spacing.medium)
                
                // Main scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with assistant character (fades on scroll)
                        VStack(spacing: Spacing.medium) {
                            Text("🤖")
                                .font(.system(size: 60))
                                .padding(.top, Spacing.large)
                            
                            VStack(spacing: Spacing.small) {
                                Text("Let's Get Started!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("I'll help you choose some habits to begin your journey. Tap the + button to add any habits that interest you.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Spacing.large)
                            }
                        }
                        .padding(.bottom, Spacing.large)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0)
                                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                        }
                        
                        // Suggestions list
                        LazyVStack(spacing: Spacing.medium) {
                            ForEach(suggestions) { suggestion in
                                HabitSuggestionRow(
                                    suggestion: suggestion,
                                    isAdded: addedHabits.contains(suggestion.id),
                                    isCreating: isCreatingHabit,
                                    isDeleting: isDeletingHabit,
                                    onAdd: {
                                        await addHabit(suggestion)
                                    },
                                    onRemove: {
                                        await removeHabit(suggestion)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.medium)
                        .padding(.bottom, Spacing.xlarge)
                    }
                }
            }
            .navigationTitle("Habit Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        userActionTracker?.track(.habitsAssistantClosed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addHabit(_ suggestion: HabitSuggestion) async {
        guard !addedHabits.contains(suggestion.id) else { return }
        
        // Track habit suggestion viewed when user attempts to add it
        userActionTracker?.track(.habitsAssistantHabitSuggestionViewed(
            habitId: suggestion.id,
            category: categoryName(for: suggestion.category)
        ))
        
        isCreatingHabit = true
        let result = await onHabitCreate(suggestion)
        
        switch result {
        case .success(let habitId):
            addedHabits.insert(suggestion.id)
            createdHabits[suggestion.id] = habitId
            userActionTracker?.track(.habitsAssistantHabitAdded(
                habitId: suggestion.id,
                habitName: suggestion.name,
                category: categoryName(for: suggestion.category)
            ))
        case .limitReached:
            // Dismiss the assistant first, then show paywall
            userActionTracker?.track(.habitsAssistantHabitAddFailed(
                habitId: suggestion.id,
                error: "Habit limit reached"
            ))
            dismiss()
            // Show paywall after a longer delay to allow dismissal to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onShowPaywall()
            }
        case .error(let errorMessage):
            userActionTracker?.track(.habitsAssistantHabitAddFailed(
                habitId: suggestion.id,
                error: errorMessage
            ))
        }
        
        isCreatingHabit = false
    }
    
    private func removeHabit(_ suggestion: HabitSuggestion) async {
        guard addedHabits.contains(suggestion.id),
              let habitId = createdHabits[suggestion.id] else { return }
        
        isDeletingHabit = true
        let success = await onHabitRemove(habitId)
        
        if success {
            addedHabits.remove(suggestion.id)
            createdHabits.removeValue(forKey: suggestion.id)
            userActionTracker?.track(.habitsAssistantHabitRemoved(
                habitId: suggestion.id,
                habitName: suggestion.name,
                category: categoryName(for: suggestion.category)
            ))
        } else {
            userActionTracker?.track(.habitsAssistantHabitRemoveFailed(
                habitId: suggestion.id,
                error: "Failed to remove habit"
            ))
        }
        
        isDeletingHabit = false
    }
    
    /// Maps existing habits to suggestion IDs based on similar characteristics
    private static func mapExistingHabitsToSuggestions(_ habits: [Habit]) -> (Set<String>, [String: UUID]) {
        var mappedSuggestions: Set<String> = []
        var habitMappings: [String: UUID] = [:]
        
        for habit in habits {
            if let suggestionId = findMatchingSuggestionId(for: habit.name.lowercased()) {
                mappedSuggestions.insert(suggestionId)
                habitMappings[suggestionId] = habit.id
            }
        }
        
        return (mappedSuggestions, habitMappings)
    }
    
    /// Find matching suggestion ID for a habit name
    private static func findMatchingSuggestionId(for lowercaseName: String) -> String? {
        let mappings = getHabitNameMappings()
        
        for (keywords, suggestionId) in mappings where matchesKeywords(lowercaseName, keywords: keywords) {
            return suggestionId
        }
        
        return nil
    }
    
    /// Get habit name to suggestion ID mappings
    private static func getHabitNameMappings() -> [([String], String)] {
        [
            (["water", "drink"], "drink_water"),
            (["exercise", "workout"], "exercise"),
            (["walk", "step"], "walk_steps"),
            (["fruit"], "eat_fruits"),
            (["meditat"], "meditate"),
            (["sleep"], "sleep_early"),
            (["breath"], "deep_breathing"),
            (["gratitude", "journal"], "gratitude"),
            (["phone", "morning"], "no_phone_morning"),
            (["plan"], "plan_day"),
            (["clean", "tidy"], "clean_workspace"),
            (["read"], "read_book"),
            (["language"], "practice_language"),
            (["learn", "skill"], "learn_skill"),
            (["call", "family"], "call_family"),
            (["compliment"], "compliment_someone"),
            (["help"], "help_others")
        ]
    }
    
    /// Check if habit name matches any of the keywords
    private static func matchesKeywords(_ habitName: String, keywords: [String]) -> Bool {
        // Special case for phone + morning combination
        if keywords == ["phone", "morning"] {
            return habitName.contains("phone") && habitName.contains("morning")
        }
        
        // For other cases, check if any keyword is contained in the habit name
        return keywords.contains { habitName.contains($0) }
    }
    
    private func categoryName(for category: HabitSuggestionCategory) -> String {
        switch category {
        case .health: return "health"
        case .wellness: return "wellness"
        case .productivity: return "productivity"
        case .learning: return "learning"
        case .social: return "social"
        }
    }
}

private struct CategoryChip: View {
    let category: HabitSuggestionCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    private var categoryInfo: (String, String) {
        switch category {
        case .health:
            return ("Health", "💪")
        case .wellness:
            return ("Wellness", "🧘")
        case .productivity:
            return ("Productivity", "⚡")
        case .learning:
            return ("Learning", "📚")
        case .social:
            return ("Social", "👥")
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.small) {
                Text(categoryInfo.1)
                Text(categoryInfo.0)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(
                isSelected ? AppColors.brand : Color(.systemGray6),
                in: Capsule()
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct HabitSuggestionRow: View {
    let suggestion: HabitSuggestion
    let isAdded: Bool
    let isCreating: Bool
    let isDeleting: Bool
    let onAdd: () async -> Void
    let onRemove: () async -> Void
    
    private var scheduleText: String {
        switch suggestion.schedule {
        case .daily:
            return "Daily"
        case .daysOfWeek(let days):
            let dayNames = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let selectedDays = days.compactMap { day in
                day <= dayNames.count - 1 ? dayNames[day] : nil
            }
            return selectedDays.joined(separator: ", ")
        case .timesPerWeek(let times):
            return "\(times)× per week"
        }
    }
    
    private var targetText: String? {
        guard let target = suggestion.dailyTarget,
              let unit = suggestion.unitLabel else { return nil }
        return "\(Int(target)) \(unit)"
    }
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Emoji and color indicator
            ZStack {
                Circle()
                    .fill(Color(hex: suggestion.colorHex) ?? AppColors.brand)
                    .frame(width: 50, height: 50)
                
                Text(suggestion.emoji)
                    .font(.title2)
            }
            
            // Habit info
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                Text(suggestion.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: Spacing.small) {
                    Text(scheduleText)
                        .font(.caption)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5), in: Capsule())
                    
                    if let target = targetText {
                        Text(target)
                            .font(.caption)
                            .padding(.horizontal, Spacing.small)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5), in: Capsule())
                    }
                }
            }
            
            Spacer()
            
            // Add/Remove button
            Button(action: {
                Task { 
                    if isAdded {
                        await onRemove()
                    } else {
                        await onAdd()
                    }
                }
            }, label: {
                ZStack {
                    Circle()
                        .fill(isAdded ? Color.green : AppColors.brand)
                        .frame(width: 32, height: 32)
                    
                    if (isCreating && !isAdded) || (isDeleting && isAdded) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if isAdded {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            })
            .disabled(isCreating || isDeleting)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(Spacing.medium)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

#Preview {
    HabitAssistantSheet(
        suggestionsService: DefaultHabitSuggestionsService(),
        onHabitCreate: { suggestion in
            // Mock implementation - simulate creating habit from suggestion
            print("Preview: Creating habit '\(suggestion.name)' with emoji \(suggestion.emoji)")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            return .success(habitId: UUID())
        },
        onHabitRemove: { habitId in
            // Mock implementation - simulate removing habit
            print("Preview: Removing habit with ID \(habitId)")
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second
            return true
        },
        onShowPaywall: {
            print("Preview: Show paywall")
        },
        userActionTracker: DebugUserActionTracker()
    )
}