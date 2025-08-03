import SwiftUI

public struct HabitsRoot: View {
    @Environment(\.appContainer) private var di
    @State private var vm: HabitsViewModel?
    @State private var isInitializing = true
    private let factory: HabitsFactory?
    
    public init(factory: HabitsFactory? = nil) { 
        self.factory = factory
    }
    
    public var body: some View {
        Group {
            if isInitializing {
                ProgressView("Initializing...")
            } else if let vm = vm {
                HabitsContentView(vm: vm)
            } else {
                ErrorView(
                    title: "Failed to Initialize",
                    message: "Unable to set up the habits screen"
                ) {
                    await initializeAndLoad()
                }
            }
        }
        .navigationTitle("Habits")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await initializeAndLoad()
        }
    }
    
    @MainActor
    private func initializeAndLoad() async {
        let actualFactory = factory ?? HabitsFactory(container: di)
        vm = actualFactory.makeViewModel()
        await vm?.load()
        isInitializing = false
    }
}

private struct HabitsContentView: View {
    @Environment(\.appContainer) private var appContainer
    @Bindable var vm: HabitsViewModel
    
    var body: some View {
        HabitsListView(vm: vm)
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
                if let assistantVM = vm.habitsAssistantViewModel {
                    HabitsAssistantSheet(
                        vm: assistantVM,
                        existingHabits: vm.items,
                        onHabitCreate: vm.createHabitFromSuggestion,
                        onHabitRemove: { habitId in await vm.delete(id: habitId) },
                        onShowPaywall: vm.showPaywallFromAssistant
                    )
                    .onDisappear {
                        vm.handleAssistantDismissal()
                    }
                }
            }
            .sheet(isPresented: $vm.showingCategoryManagement) {
                categoryManagementSheet
            }
            .onChange(of: vm.paywallItem) { oldValue, newValue in
                // When paywall item becomes nil, the sheet is dismissed
                if oldValue != nil && newValue == nil {
                    vm.handlePaywallDismissal()
                }
            }
    }
    
    @ViewBuilder
    private var categoryManagementSheet: some View {
        NavigationStack {
            let factory = SettingsFactory(container: appContainer)
            CategoryManagementView(vm: factory.makeCategoryManagementViewModel())
                .onDisappear {
                    vm.handleCategoryManagementDismissal()
                }
        }
    }
}

private struct HabitsListView: View {
    @Environment(\.editMode) private var editMode
    @Bindable var vm: HabitsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var habitToDelete: Habit?
    @State private var selection: Set<UUID> = []
    
    var body: some View {
        Group {
            // if vm.isLoading {
            //     ProgressView()
            // } else 
            if let error = vm.error {
                ErrorView(
                    title: Strings.Error.failedLoadHabits,
                    message: error.localizedDescription
                ) {
                    await vm.retry()
                }
            } else if vm.filteredHabits.isEmpty {
                VStack(spacing: 0) {
                    // Always show category filters, even when empty
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
                    
                    // Edit button and actions positioned above the empty state
                    HStack {
                        Spacer()
                        
                        HStack(spacing: Spacing.small) {
                            Button {
                                vm.handleAssistantTap(source: "emptyState")
                            } label: {
                                Image(systemName: "lightbulb.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Habits Assistant")
                            
                            EditButton()
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Button {
                                vm.handleCreateHabitTap()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Add Habit")
                        }
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.small)
                    }
                    
                    VStack(spacing: Spacing.xlarge) {
                        if vm.selectedFilterCategory != nil {
                            // Empty state when filtering
                            ContentUnavailableView(
                                "No habits in this category",
                                systemImage: "tray",
                                description: Text("No habits found for the selected category. Try selecting a different category or create a new habit.")
                            )
                        } else {
                            // Empty state when no habits at all
                            ContentUnavailableView(
                                Strings.EmptyState.noHabitsYet,
                                systemImage: "plus.circle",
                                description: Text(Strings.EmptyState.tapPlusToCreate)
                            )
                        }
                    }
                }
            } else {
                VStack(spacing: 0) {
                    // Always show the header with add button, categories if available
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
                    
                    // Edit button and actions positioned above the list
                    HStack {
                        Spacer()
                        
                        HStack(spacing: Spacing.small) {
                            Button {
                                vm.handleAssistantTap(source: "habitsPage")
                            } label: {
                                Image(systemName: "lightbulb.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Habits Assistant")
                            
                            EditButton()
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Button {
                                vm.handleCreateHabitTap()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Add Habit")
                        }
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.small)
                    }
                    
                    List(selection: $selection) {
                        ForEach(vm.filteredHabits, id: \.id) { habit in
                            HabitRowView(habit: habit) {
                                vm.selectHabit(habit)
                            }
                            .tag(habit.id)
                            .swipeActions(edge: .leading) {
                                // Only show swipe actions when not in edit mode
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
                    .refreshable {
                        await vm.load()
                    }
                    .onChange(of: editMode?.wrappedValue) { oldValue, newValue in
                        // Clear selection when exiting edit mode
                        if oldValue == .active && newValue != .active {
                            selection.removeAll()
                        }
                    }
                    
                    // Bottom content - either edit toolbar or assistant button
                    VStack(spacing: 0) {
                        if !selection.isEmpty {
                            editModeToolbar
                        } else {
                            // Habit assistant - commented out, moved to navigation bar
                            // AssistantButton {
                            //     vm.handleAssistantTap(source: "habitsPage")
                            // }
                            // .padding(.horizontal, Spacing.large)
                            // .padding(.vertical, Spacing.medium)
                            
                            Spacer()
                                .frame(height: Spacing.large)
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
            Spacer()
            
            // Activate button (only show if inactive habits are selected)
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
            
            // Deactivate button (only show if active habits are selected)
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
            
            // Delete button
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
            
            Spacer()
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
        // When filtering is active, disable reordering to avoid confusion
        guard vm.selectedFilterCategory == nil else { return }
        
        // Work with the filtered habits that the user sees, but update the full list
        var reorderedHabits = vm.filteredHabits
        reorderedHabits.move(fromOffsets: source, toOffset: destination)
        
        // Update display order based on new positions
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
        
        // Save the reordered habits
        for habit in reorderedHabits {
            _ = await vm.update(habit)
        }
        
        // Refresh to show updated order
        await vm.load()
    }
}

private struct HabitRowView: View {
    let habit: Habit
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            Color(hex: habit.colorHex)?
                                .opacity(0.1) ?? .blue
                                .opacity(0.1)
                        )
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
            }
        }
        .buttonStyle(PlainButtonStyle())
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

private struct AssistantButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AppColors.brand.opacity(0.1))
                        .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)
                    
                    Text("🤖")
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    Text("Habit Assistant")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Get personalized habit suggestions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.brand)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.brand.opacity(0.2), lineWidth: ComponentSize.separatorThin)
        )
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a_component, r_component, g_component, b_component: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a_component, r_component, g_component, b_component) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a_component, r_component, g_component, b_component) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a_component, r_component, g_component, b_component) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(.sRGB, red: Double(r_component) / 255, green: Double(g_component) / 255, blue: Double(b_component) / 255, opacity: Double(a_component) / 255)
    }
}

#Preview {
    let container = DefaultAppContainer.createMinimal()
    return HabitsRoot(factory: HabitsFactory(container: container))
        .environment(\.appContainer, container)
}
