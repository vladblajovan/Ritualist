import SwiftUI
import RitualistCore

// MARK: - HabitsListView Computed Properties

extension HabitsListView {

    // MARK: - Header Configuration

    var headerActions: [HeaderAction] {
        var actions: [HeaderAction] = []

        // Edit button - only show when habits exist
        if !vm.filteredHabits.isEmpty {
            actions.append(HeaderAction(
                icon: isEditMode ? "checkmark" : "pencil",
                accessibilityLabel: isEditMode ? "Done editing" : "Edit habits"
            ) {
                HapticFeedbackService.shared.trigger(.light)
                withAnimation {
                    editMode?.wrappedValue = isEditMode ? .inactive : .active
                }
            })
        }

        // Add habit button
        actions.append(HeaderAction(
            icon: "plus",
            accessibilityLabel: "Add habit"
        ) {
            vm.handleCreateHabitTap()
        })

        return actions
    }

    @ViewBuilder
    var stickyBrandHeader: some View {
        AppBrandHeader(
            completionPercentage: vm.todayCompletionPercentage,
            progressDisplayStyle: .circular,
            actions: headerActions
        )
        .padding(.top, Spacing.medium)
        .zIndex(1)
    }

    // MARK: - Selection State

    var hasActiveSelectedHabits: Bool {
        let selectedHabits = vm.filteredHabits.filter { selection.contains($0.id) }
        return selectedHabits.contains { $0.isActive }
    }

    var hasInactiveSelectedHabits: Bool {
        let selectedHabits = vm.filteredHabits.filter { selection.contains($0.id) }
        return selectedHabits.contains { !$0.isActive }
    }

    // MARK: - Confirmation Messages

    var batchDeleteConfirmationMessage: String {
        // Use the live selection for counting, but filter to get actual habits to delete
        let habitsToCount = habitsToDelete.isEmpty ? selection : habitsToDelete
        let selectedHabits = vm.filteredHabits.filter { habitsToCount.contains($0.id) }

        if selectedHabits.count == 1 {
            return "Are you sure you want to delete \"\(selectedHabits.first!.name)\"? This action cannot be undone and all habit data will be lost."
        } else {
            return "Are you sure you want to delete \(selectedHabits.count) habits? This action cannot be undone and all habit data will be lost."
        }
    }

    var deactivateConfirmationMessage: String {
        // Use the live selection for counting, but filter to get actual habits to deactivate
        let habitsToCount = habitsToDeactivate.isEmpty ? selection : habitsToDeactivate
        let selectedHabits = vm.filteredHabits.filter { habitsToCount.contains($0.id) && $0.isActive }

        if selectedHabits.count == 1 {
            return "Are you sure you want to deactivate \"\(selectedHabits.first!.name)\"? It will be hidden from your habits list but existing data will remain."
        } else {
            return "Are you sure you want to deactivate \(selectedHabits.count) habits? They will be hidden from your habits list but existing data will remain."
        }
    }

    // MARK: - Background View

    @ViewBuilder
    var backgroundGradientView: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    AppColors.brand.opacity(0.25),
                    AppColors.brand.opacity(0.12),
                    AppColors.accentCyan.opacity(0.06),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)

            Color(.systemGroupedBackground).opacity(0.03)
        }
        .ignoresSafeArea()
    }
}
