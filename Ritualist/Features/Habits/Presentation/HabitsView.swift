import SwiftUI
import FactoryKit
import RitualistCore

public struct HabitsRoot: View {
    @Injected(\.habitsViewModel) var vm
    @Injected(\.categoryManagementViewModel) var categoryManagementVM
    @State private var showingCategoryManagement = false

    public init() {}

    public var body: some View {
        HabitsContentView(
            vm: vm,
            showingCategoryManagement: $showingCategoryManagement
        )
        .task {
            await vm.load()
        }
        .sheet(isPresented: $showingCategoryManagement, onDismiss: {
            Task {
                await vm.load()
            }
        }) {
            NavigationStack {
                CategoryManagementView(vm: categoryManagementVM)
            }
        }
    }
}

private struct HabitsContentView: View {
    @Environment(\.editMode) private var editMode
    @Bindable var vm: HabitsViewModel
    @Binding var showingCategoryManagement: Bool
    @State private var dragOffset = CGSize.zero

    private var isEditMode: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        GeometryReader { geometry in
            HabitsListView(
                vm: vm,
                showingCategoryManagement: $showingCategoryManagement
            )
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Primary action: Add Habit
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        vm.handleCreateHabitTap()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .accessibilityLabel("Add Habit")
                    .accessibilityHint("Create a new habit to track")
                }

                // Secondary action: Edit mode
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(.secondary)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Draggable Floating AI Assistant button - hidden in edit mode
                if !isEditMode {
                    DraggableFloatingButton(
                        dragOffset: $dragOffset,
                        screenSize: geometry.size,
                        safeAreaInsets: geometry.safeAreaInsets,
                        onTap: {
                            vm.handleAssistantTap(source: "fab")
                        }
                    )
                    .padding(.trailing, Spacing.large)
                    .padding(.bottom, Spacing.large)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Ensure content doesn't get hidden by FAB - only when FAB is visible
                if !isEditMode {
                    Color.clear.frame(height: 80)
                }
            }
        }
            .sheet(isPresented: $vm.showingCreateHabit) {
                let detailVM = vm.makeHabitDetailViewModel(for: nil)
                HabitDetailView(vm: detailVM)
                    .onDisappear {
                        if detailVM.didMakeChanges {
                            vm.handleCreateHabitDismissal()
                        }
                    }
            }
            .sheet(item: $vm.paywallItem) { item in
                PaywallView(vm: item.viewModel)
            }
            .sheet(isPresented: $vm.showingHabitAssistant) {
                HabitsAssistantSheet(
                    existingHabits: vm.items,
                    onShowPaywall: {
                        // Dismiss Assistant and show paywall
                        vm.showingHabitAssistant = false
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                            await MainActor.run {
                                vm.showPaywall()
                            }
                        }
                    }
                )
                .onDisappear {
                    vm.handleAssistantDismissal()
                }
            }
            .onChange(of: vm.paywallItem) { oldValue, newValue in
                if oldValue != nil && newValue == nil {
                    vm.handlePaywallDismissal()
                }
            }
    }
}

// swiftlint:disable type_body_length
private struct HabitsListView: View {
    @Environment(\.editMode) private var editMode
    @Bindable var vm: HabitsViewModel
    @Binding var showingCategoryManagement: Bool
    @State private var showingDeleteConfirmation = false
    @State private var showingBatchDeleteConfirmation = false
    @State private var showingDeactivateConfirmation = false
    @State private var habitToDelete: Habit?
    @State private var habitsToDelete: Set<UUID> = []
    @State private var habitsToDeactivate: Set<UUID> = []
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
                        // Reusable category carousel with cogwheel
                        CategoryCarouselWithManagement(
                            categories: vm.displayCategories,
                            selectedCategory: vm.selectedFilterCategory,
                            onCategoryTap: { category in
                                vm.selectFilterCategory(category)
                            },
                            onManageTap: {
                                showingCategoryManagement = true
                            },
                            scrollToStartOnSelection: true,
                            allowDeselection: true
                        )
                        .padding(.top, Spacing.small)
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
                        .padding(.horizontal, Spacing.screenMargin)
                        .padding(.vertical, Spacing.medium)
                        .background(Color(.systemBackground))
                    } else {
                        // Reusable category carousel with cogwheel
                        CategoryCarouselWithManagement(
                            categories: vm.displayCategories,
                            selectedCategory: vm.selectedFilterCategory,
                            onCategoryTap: { category in
                                vm.selectFilterCategory(category)
                            },
                            onManageTap: {
                                showingCategoryManagement = true
                            },
                            scrollToStartOnSelection: true,
                            allowDeselection: true
                        )
                        .padding(.vertical, Spacing.small)
                        .background(Color(.systemBackground))
                    }

                    // Over-limit banner (if user has more habits than free plan allows)
                    if vm.isOverFreeLimit {
                        OverLimitBannerView(
                            currentCount: vm.habitsData.totalHabitsCount,
                            maxCount: vm.freeMaxHabits,
                            onUpgradeTap: {
                                vm.showPaywall()
                            }
                        )
                        .padding(.horizontal, Spacing.screenMargin)
                        .padding(.vertical, Spacing.small)
                        .background(Color(.systemBackground))
                    }

                    // Scrollable content with categories header, buttons and habits
                    List(selection: $selection) {
                        
                        // Habits section
                        Section {
                            ForEach(vm.filteredHabits, id: \.id) { habit in
                                GenericRowView.habitRowWithSchedule(
                                    habit: habit,
                                    scheduleStatus: vm.getScheduleStatus(for: habit)
                                ) {
                                    vm.selectHabit(habit)
                                }
                                .tag(habit.id)
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
                    .listStyle(.insetGrouped)
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
                    if detailVM.didMakeChanges {
                        vm.handleHabitDetailDismissal()
                    }
                }
        }
        .confirmationDialog(
            "Delete Habit",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            if let habit = habitToDelete {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteHabit(habit)
                        habitToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    habitToDelete = nil
                }
            }
        } message: {
            if let habit = habitToDelete {
                Text("Are you sure you want to delete \"\(habit.name)\"? This action cannot be undone and all habit data will be lost.")
            }
        }
        .confirmationDialog(
            "Delete Habits",
            isPresented: $showingBatchDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    print("DEBUG: Habits batch delete dialog confirmed")
                    await deleteSelectedHabits()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(batchDeleteConfirmationMessage)
        }
        .confirmationDialog(
            "Deactivate Habits", 
            isPresented: $showingDeactivateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Deactivate", role: .destructive) {
                Task {
                    print("DEBUG: Habits deactivate dialog confirmed")
                    await deactivateSelectedHabits()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(deactivateConfirmationMessage)
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
                    habitsToDeactivate = selection
                    showingDeactivateConfirmation = true
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
                habitsToDelete = selection
                showingBatchDeleteConfirmation = true
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
    
    private var batchDeleteConfirmationMessage: String {
        // Use the live selection for counting, but filter to get actual habits to delete
        let habitsToCount = habitsToDelete.isEmpty ? selection : habitsToDelete
        let selectedHabits = vm.filteredHabits.filter { habitsToCount.contains($0.id) }
        
        if selectedHabits.count == 1 {
            return "Are you sure you want to delete \"\(selectedHabits.first!.name)\"? This action cannot be undone and all habit data will be lost."
        } else {
            return "Are you sure you want to delete \(selectedHabits.count) habits? This action cannot be undone and all habit data will be lost."
        }
    }
    
    private var deactivateConfirmationMessage: String {
        // Use the live selection for counting, but filter to get actual habits to deactivate
        let habitsToCount = habitsToDeactivate.isEmpty ? selection : habitsToDeactivate
        let selectedHabits = vm.filteredHabits.filter { habitsToCount.contains($0.id) && $0.isActive }
        
        if selectedHabits.count == 1 {
            return "Are you sure you want to deactivate \"\(selectedHabits.first!.name)\"? It will be hidden from your habits list but existing data will remain."
        } else {
            return "Are you sure you want to deactivate \(selectedHabits.count) habits? They will be hidden from your habits list but existing data will remain."
        }
    }
    
    private func activateSelectedHabits() async {
        for habitId in selection {
            await vm.toggleActiveStatus(id: habitId)
        }
        selection.removeAll()
    }
    
    private func deactivateSelectedHabits() async {
        print("DEBUG: deactivateSelectedHabits called with \(habitsToDeactivate.count) habits")
        for habitId in habitsToDeactivate {
            print("DEBUG: Toggling active status for habit: \(habitId)")
            await vm.toggleActiveStatus(id: habitId)
        }
        selection.removeAll()
    }
    
    private func deleteSelectedHabits() async {
        print("DEBUG: deleteSelectedHabits called with \(habitsToDelete.count) habits")
        for habitId in habitsToDelete {
            print("DEBUG: Deleting habit: \(habitId)")
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

private struct DraggableFloatingButton: View {
    @Binding var dragOffset: CGSize
    let screenSize: CGSize
    let safeAreaInsets: EdgeInsets
    let onTap: () -> Void

    @GestureState private var temporaryOffset: CGSize = .zero
    @State private var isDragging = false

    private let buttonSize: CGFloat = 60
    private let padding: CGFloat = 16

    var body: some View {
        ZStack {
            // Glassmorphic background
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 4)
                .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)

            // AI icon with gradient
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: buttonSize, height: buttonSize)
        .scaleEffect(isDragging ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
        .accessibilityLabel("AI Habits Assistant")
        .accessibilityHint("Drag to reposition or tap to open. Get personalized habit suggestions and insights")
        .offset(
            x: dragOffset.width + temporaryOffset.width,
            y: dragOffset.height + temporaryOffset.height
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($temporaryOffset) { value, state, _ in
                    state = value.translation
                    isDragging = true
                }
                .onEnded { value in
                    isDragging = false

                    // Calculate drag distance
                    let dragDistance = sqrt(
                        value.translation.width * value.translation.width +
                        value.translation.height * value.translation.height
                    )

                    // If drag distance is less than 10 points, treat it as a tap
                    if dragDistance < 10 {
                        onTap()
                    } else {
                        // It was a drag - accumulate the offset with boundary constraints
                        let newOffsetWidth = dragOffset.width + value.translation.width
                        let newOffsetHeight = dragOffset.height + value.translation.height

                        // Calculate available draggable area respecting safe areas
                        // Button starts at bottom-trailing with padding
                        // Available width for dragging (accounting for safe areas)
                        let availableWidth = screenSize.width - safeAreaInsets.leading - safeAreaInsets.trailing - buttonSize - padding * 2
                        let availableHeight = screenSize.height - safeAreaInsets.top - safeAreaInsets.bottom - buttonSize - padding * 2 - 80 // 80 for bottom safe area inset

                        // Max left: can drag to left edge (respecting leading safe area)
                        let maxLeft = -availableWidth
                        let maxRight: CGFloat = 0
                        // Max up: can drag to top (respecting top safe area)
                        let maxUp = -availableHeight
                        let maxDown: CGFloat = 0

                        let constrainedWidth = max(maxLeft, min(maxRight, newOffsetWidth))
                        let constrainedHeight = max(maxUp, min(maxDown, newOffsetHeight))

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = CGSize(
                                width: constrainedWidth,
                                height: constrainedHeight
                            )
                        }
                    }
                }
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Over-Limit Banner

private struct OverLimitBannerView: View {
    let currentCount: Int
    let maxCount: Int
    let onUpgradeTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Info icon
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            // Message
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                Text("\(currentCount)/\(maxCount) habits (Free)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("Upgrade to Pro for unlimited habits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Upgrade button
            Button(action: onUpgradeTap) {
                Text("Upgrade")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HabitsRoot()
}
