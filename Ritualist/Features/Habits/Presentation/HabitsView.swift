import SwiftUI
import FactoryKit
import RitualistCore

public struct HabitsRoot: View {
    @Injected(\.habitsViewModel) var vm
    
    public init() {}
    
    public var body: some View {
        HabitsContentView(vm: vm)
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await vm.load()
            }
    }
}

private struct HabitsContentView: View {
    @Bindable var vm: HabitsViewModel
    @Injected(\.categoryManagementViewModel) var categoryManagementVM
    
    var body: some View {
        HabitsListView(vm: vm)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.handleAssistantTap(source: "toolbar")
                    } label: {
                        HStack(spacing: Spacing.small) {
                            Image(systemName: "lightbulb.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Assistant")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    .accessibilityLabel("Habits Assistant")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(AppColors.brand)
                        .buttonStyle(PlainButtonStyle())
                }
                
                // DEBUG: Temporary cleanup button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await vm.debugCleanupOrphanedHabits()
                        }
                    } label: {
                        Text("🧹")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.handleCreateHabitTap()
                    } label: {
                        Text("Add")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.brand)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .sheet(isPresented: $vm.showingCreateHabit) {
                let detailVM = vm.makeHabitDetailViewModel(for: nil)
                HabitDetailView(vm: detailVM)
                    .onDisappear {
                        vm.handleCreateHabitDismissal()
                    }
            }
            .sheet(item: $vm.paywallItem) { item in
                PaywallView(vm: item.viewModel)
            }
            .sheet(isPresented: $vm.showingHabitAssistant) {
                HabitsAssistantSheet(
                    vm: vm.habitsAssistantViewModel,
                    existingHabits: vm.items,
                    onHabitCreate: vm.createHabitFromSuggestion,
                    onHabitRemove: { habitId in await vm.delete(id: habitId) },
                    onShowPaywall: vm.showPaywallFromAssistant
                )
                .onDisappear {
                    vm.handleAssistantDismissal()
                }
            }
            .sheet(isPresented: $vm.showingCategoryManagement) {
                categoryManagementSheet
            }
            .onChange(of: vm.paywallItem) { oldValue, newValue in
                if oldValue != nil && newValue == nil {
                    vm.handlePaywallDismissal()
                }
            }
    }
    
    @ViewBuilder
    private var categoryManagementSheet: some View {
        NavigationStack {
            CategoryManagementView(vm: categoryManagementVM)
                .onDisappear {
                    vm.handleCategoryManagementDismissal()
                }
        }
    }
}

// swiftlint:disable type_body_length
private struct HabitsListView: View {
    @Environment(\.editMode) private var editMode
    @Bindable var vm: HabitsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var habitToDelete: Habit?
    @State private var selection: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            if let error = vm.error {
                ErrorView(
                    title: Strings.Error.failedLoadHabits,
                    message: error.localizedDescription
                ) {
                    await vm.retry()
                }
            } else if vm.filteredHabits.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        CategoryFilterCarousel(
                            selectedCategory: Binding(
                                get: { vm.selectedFilterCategory },
                                set: { vm.selectFilterCategory($0) }
                            ),
                            categories: vm.categories,
                            isLoading: vm.isLoadingCategories,
                            onCategorySelect: { category in
                                vm.selectFilterCategory(category)
                            },
                            onManageCategories: {
                                vm.handleCategoryManagementTap()
                            },
                            onAddHabit: nil,
                            onAssistant: nil
                        )
                        .padding(.bottom, Spacing.medium)
                        
                        VStack(spacing: Spacing.xlarge) {
                            if vm.selectedFilterCategory != nil {
                                ContentUnavailableView(
                                    "No habits in this category",
                                    systemImage: "tray",
                                    description: Text("No habits found for the selected category. Try selecting a different category or create a new habit.")
                                )
                            } else {
                                ContentUnavailableView(
                                    Strings.EmptyState.noHabitsYet,
                                    systemImage: "plus.circle",
                                    description: Text(Strings.EmptyState.tapPlusToCreate)
                                )
                            }
                        }
                        .padding(.top, Spacing.large)
                    }
                }
                .refreshable {
                    await vm.load()
                }
            } else {
                VStack(spacing: 0) {
                    // Sticky category chips only
                    if vm.isLoadingCategories {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading categories...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, Spacing.large)
                        .padding(.vertical, Spacing.medium)
                        .background(Color(.systemBackground))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.medium) {
                                ForEach(vm.categories, id: \.id) { category in
                                    Chip(
                                        text: category.displayName,
                                        emoji: category.emoji,
                                        isSelected: vm.selectedFilterCategory?.id == category.id
                                    )
                                    .onTapGesture {
                                        if vm.selectedFilterCategory?.id == category.id {
                                            vm.selectFilterCategory(nil)
                                        } else {
                                            vm.selectFilterCategory(category)
                                        }
                                    }
                                    .onLongPressGesture {
                                        vm.handleCategoryManagementTap()
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.large)
                        }
                        .padding(.vertical, Spacing.small)
                        .background(Color(.systemBackground))
                    }
                    
                    // Scrollable content with categories header, buttons and habits
                    List(selection: $selection) {
                        // Categories header section (scrollable - will hide on scroll)
                        Section {
                            HStack {
                                Text("Categories")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Button {
                                    vm.handleCategoryManagementTap()
                                } label: {
                                    HStack(spacing: Spacing.xsmall) {
                                        Image(systemName: "gear")
                                            .font(.caption)
                                        Text("Manage")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.large)
                            .padding(.vertical, Spacing.small)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                        
                        // Habits section
                        Section {
                            ForEach(vm.filteredHabits, id: \.id) { habit in
                                HabitRowView(habit: habit) {
                                    vm.selectHabit(habit)
                                }
                                .tag(habit.id)
                                .onTapGesture {
                                    // Intercept List row taps - do nothing
                                }
                                .swipeActions(edge: .leading) {
                                    if editMode?.wrappedValue != .active {
                                        Button {
                                            Task {
                                                await vm.toggleActiveStatus(id: habit.id)
                                            }
                                        } label: {
                                            Label(
                                                habit.isActive ? Strings.Button.deactivate : Strings.Button.activate,
                                                systemImage: habit.isActive ? "pause.circle" : "play.circle"
                                            )
                                        }
                                        .tint(habit.isActive ? .orange : .green)
                                    }
                                }
                            }
                            .onDelete(perform: { indexSet in
                                if let index = indexSet.first {
                                    habitToDelete = vm.filteredHabits[index]
                                    showingDeleteConfirmation = true
                                }
                            })
                            .onMove(perform: { source, destination in
                                Task {
                                    await handleMove(from: source, to: destination)
                                }
                            })
                        }
                    }
                    .refreshable {
                        await vm.load()
                    }
                    .onChange(of: editMode?.wrappedValue) { oldValue, newValue in
                        if oldValue == .active && newValue != .active {
                            selection.removeAll()
                        }
                    }
                    .listStyle(PlainListStyle())
                    .overlay(alignment: .bottom) {
                        if !selection.isEmpty {
                            editModeToolbar
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if vm.isCreating || vm.isUpdating || vm.isDeleting {
                OperationStatusView(
                    isCreating: vm.isCreating,
                    isUpdating: vm.isUpdating,
                    isDeleting: vm.isDeleting
                )
                .padding()
            }
        }
        .sheet(item: $vm.selectedHabit) { habit in
            let detailVM = vm.makeHabitDetailViewModel(for: habit)
            HabitDetailView(vm: detailVM)
                .onDisappear {
                    vm.handleHabitDetailDismissal()
                }
        }
        .confirmationDialog(isPresented: $showingDeleteConfirmation) {
            if let habit = habitToDelete {
                ConfirmationDialog(
                    title: Strings.Dialog.deleteHabit,
                    message: Strings.Dialog.deleteHabitMessage(habit.name),
                    confirmTitle: Strings.Button.delete,
                    cancelTitle: Strings.Button.cancel,
                    isDestructive: true,
                    onConfirm: {
                        await deleteHabit(habit)
                        showingDeleteConfirmation = false
                        habitToDelete = nil
                    },
                    onCancel: {
                        showingDeleteConfirmation = false
                        habitToDelete = nil
                    }
                )
            }
        }
    }
    
    private var editModeToolbar: some View {
        HStack(spacing: Spacing.large) {
            Text("\(selection.count) selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if hasInactiveSelectedHabits {
                Button {
                    Task {
                        await activateSelectedHabits()
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "play.circle")
                            .font(.title2)
                        Text("Activate")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.green)
            }
            
            if hasActiveSelectedHabits {
                Button {
                    Task {
                        await deactivateSelectedHabits()
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "pause.circle")
                            .font(.title2)
                        Text("Deactivate")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.orange)
            }
            
            Button {
                Task {
                    await deleteSelectedHabits()
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("Delete")
                        .font(.caption2)
                }
            }
            .foregroundColor(.red)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, Spacing.medium)
        .padding(.bottom, Spacing.small)
    }
    
    private var hasActiveSelectedHabits: Bool {
        let selectedHabits = vm.filteredHabits.filter { selection.contains($0.id) }
        return selectedHabits.contains { $0.isActive }
    }
    
    private var hasInactiveSelectedHabits: Bool {
        let selectedHabits = vm.filteredHabits.filter { selection.contains($0.id) }
        return selectedHabits.contains { !$0.isActive }
    }
    
    private func activateSelectedHabits() async {
        for habitId in selection {
            await vm.toggleActiveStatus(id: habitId)
        }
        selection.removeAll()
    }
    
    private func deactivateSelectedHabits() async {
        for habitId in selection {
            await vm.toggleActiveStatus(id: habitId)
        }
        selection.removeAll()
    }
    
    private func deleteSelectedHabits() async {
        for habitId in selection {
            await vm.delete(id: habitId)
        }
        selection.removeAll()
    }
    
    private func deleteHabit(_ habit: Habit) async {
        _ = await vm.delete(id: habit.id)
    }
    
    private func handleMove(from source: IndexSet, to destination: Int) async {
        guard vm.selectedFilterCategory == nil else { return }
        
        var reorderedHabits = vm.filteredHabits
        reorderedHabits.move(fromOffsets: source, toOffset: destination)
        
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
        
        for habit in reorderedHabits {
            _ = await vm.update(habit)
        }
        
        await vm.load()
    }
}

private struct HabitRowView: View {
    let habit: Habit
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.1))
                    .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)
                Text(habit.emoji ?? "•")
            }
            VStack(alignment: .leading) {
                Text(habit.name).bold()
                Text(habit.isActive ? Strings.Status.active : Strings.Status.inactive)
                    .font(.caption)
                    .foregroundColor(habit.isActive ? .green : .secondary)
            }
            Spacer()
            
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundColor(.secondary)
                .onTapGesture {
                    onTap()
                }
                .accessibilityLabel("View habit details")
        }
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }
}

private struct OperationStatusView: View {
    let isCreating: Bool
    let isUpdating: Bool
    let isDeleting: Bool
    
    var body: some View {
        HStack {
            if isCreating {
                ProgressView()
                    .scaleEffect(ScaleFactors.smallMedium)
                Text(Strings.Status.creating)
            } else if isUpdating {
                ProgressView()
                    .scaleEffect(ScaleFactors.smallMedium)
                Text(Strings.Status.updating)
            } else if isDeleting {
                ProgressView()
                    .scaleEffect(ScaleFactors.smallMedium)
                Text(Strings.Status.deleting)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    HabitsRoot()
}
