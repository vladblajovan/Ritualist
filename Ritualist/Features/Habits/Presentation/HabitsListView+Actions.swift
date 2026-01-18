import SwiftUI
import RitualistCore

// MARK: - HabitsListView Actions

extension HabitsListView {

    // MARK: - Batch Operations

    func activateSelectedHabits() async {
        for habitId in selection {
            _ = await vm.toggleActiveStatus(id: habitId)
        }
        selection.removeAll()
    }

    func deactivateSelectedHabits() async {
        logger.log(
            "🔕 Deactivating habits",
            level: .info,
            category: .ui,
            metadata: [
                "count": habitsToDeactivate.count,
                "habitIds": habitsToDeactivate.map { $0.uuidString }.joined(separator: ", ")
            ]
        )
        for habitId in habitsToDeactivate {
            _ = await vm.toggleActiveStatus(id: habitId)
        }
        selection.removeAll()
    }

    func deleteSelectedHabits() async {
        logger.log(
            "🗑️ Deleting habits",
            level: .info,
            category: .ui,
            metadata: [
                "count": habitsToDelete.count,
                "habitIds": habitsToDelete.map { $0.uuidString }.joined(separator: ", ")
            ]
        )
        for habitId in habitsToDelete {
            _ = await vm.delete(id: habitId)
        }
        selection.removeAll()
    }

    // MARK: - Single Habit Operations

    func deleteHabit(_ habit: Habit) async {
        _ = await vm.delete(id: habit.id)
    }

    // MARK: - Reordering

    func handleMove(from source: IndexSet, to destination: Int) async {
        guard vm.selectedFilterCategory == nil else { return }

        var reorderedHabits = vm.filteredHabits
        reorderedHabits.move(fromOffsets: source, toOffset: destination)

        // Update displayOrder for each habit
        for (index, habit) in reorderedHabits.enumerated() {
            reorderedHabits[index] = Habit(
                id: habit.id,
                name: habit.name,
                colorHex: habit.colorHex,
                emoji: habit.emoji,
                kind: habit.kind,
                unitLabel: habit.unitLabel,
                dailyTarget: habit.dailyTarget,
                schedule: habit.schedule,
                reminders: habit.reminders,
                startDate: habit.startDate,
                endDate: habit.endDate,
                isActive: habit.isActive,
                displayOrder: index,
                categoryId: habit.categoryId,
                suggestionId: habit.suggestionId
            )
        }

        // Use reorderHabits which sets isReordering (not isUpdating) to avoid overlay flash
        _ = await vm.reorderHabits(reorderedHabits)
    }
}
