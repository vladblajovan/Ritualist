////
////  OverviewHabitsCarousel.swift
////  Ritualist
////
////  Created by Vlad Blajovan on 29.07.2025.
////

import SwiftUI

struct OverviewHabitsCarousel: View {
    let habits: [Habit]
    let selectedHabit: Habit?
    let onChipTap: (Habit) async -> Void
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            // Horizontal scroll view with chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.medium) {
                    ForEach(habits, id: \.id) { habit in
                        HabitChip(
                            habit: habit,
                            isSelected: selectedHabit?.id == habit.id
                        ) {
                            await onChipTap(habit)
                        }
                    }
                }
                .padding(.horizontal, 16)
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
            
            // Page indicator (commented out as requested)
            // if habits.count > 3 {
            //     HStack(spacing: Spacing.xxsmall) {
            //         ForEach(0..<min(habits.count, 5), id: \.self) { index in
            //             Circle()
            //                 .fill(selectedHabit?.id == habits[index].id ? AppColors.brand : Color.secondary.opacity(0.3))
            //                 .frame(width: 6, height: 6)
            //         }
            //         
            //         if habits.count > 5 {
            //             Text("...")
            //                 .font(.caption2)
            //                 .foregroundColor(.secondary)
            //         }
            //     }
            //     .padding(.horizontal, 16)
            // }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}
