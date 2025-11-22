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
        ZStack {
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
                .safeAreaInset(edge: .bottom) {
                    // Ensure content doesn't get hidden by FAB - only when FAB is visible
                    if !isEditMode {
                        Color.clear.frame(height: 80)
                    }
                }
            }

            // Draggable Floating AI Assistant button - outside GeometryReader to be truly on top
            if !isEditMode {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
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
                }
                .allowsHitTesting(true)
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
    @Injected(\.debugLogger) private var logger
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
                // Unified scrolling: Everything inside List
                List(selection: $selection) {
                    // Categories and banner section (scrolls with list)
                    Section {
                        if vm.isLoadingCategories {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading categories...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.medium)
                            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenMargin, bottom: 0, trailing: Spacing.screenMargin))
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
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
                            .padding(.vertical, Spacing.small)
                            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenMargin, bottom: 0, trailing: Spacing.screenMargin))
                        }
                    }
                    .listRowBackground(Color(.systemGroupedBackground))

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
                    logger.log(
                        "🗑️ Batch delete confirmed",
                        level: .info,
                        category: .ui,
                        metadata: ["count": habitsToDelete.count]
                    )
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
                    logger.log(
                        "🔕 Batch deactivate confirmed",
                        level: .info,
                        category: .ui,
                        metadata: ["count": habitsToDeactivate.count]
                    )
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
            await vm.toggleActiveStatus(id: habitId)
        }
        selection.removeAll()
    }
    
    private func deleteSelectedHabits() async {
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
                    // Allow free dragging - no constraints during drag
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
                        // Drag completed - snap to nearest edge with top/bottom constraints
                        // Offset is relative to bottomTrailing position

                        let newWidth = dragOffset.width + value.translation.width
                        let newHeight = dragOffset.height + value.translation.height

                        // Calculate current absolute X position
                        // bottomTrailing means: screen.width - padding for x=0
                        // Moving left (negative) means we're moving toward left edge
                        let currentAbsoluteX = screenSize.width - padding + newWidth

                        // Snap to nearest edge (left or right)
                        let snapToLeft = currentAbsoluteX < screenSize.width / 2
                        let snappedWidth: CGFloat
                        if snapToLeft {
                            // Snap to left edge: need to move left by (screenWidth - padding - buttonSize - padding)
                            snappedWidth = -(screenSize.width - padding - buttonSize - padding)
                        } else {
                            // Snap to right edge (original position)
                            snappedWidth = 0
                        }

                        // Calculate vertical constraints
                        let buffer: CGFloat = 5
                        let maxUpwardOffset = -(screenSize.height - safeAreaInsets.top - buffer)
                        let maxDownwardOffset: CGFloat = 10

                        // Constrain height to stay between navigation and tab bar
                        let constrainedHeight = min(max(newHeight, maxUpwardOffset), maxDownwardOffset)

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = CGSize(
                                width: snappedWidth,
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

    private var isAtLimit: Bool {
        currentCount >= maxCount
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Info icon - changes to warning when at limit
            Image(systemName: isAtLimit ? "exclamationmark.circle.fill" : "info.circle.fill")
                .font(.title3)
                .foregroundStyle(isAtLimit ? .orange : .blue)

            // Message
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                Text("\(currentCount)/\(maxCount) habits (Free)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(isAtLimit
                     ? "Limit reached. Upgrade to Pro for unlimited habits"
                     : "Upgrade to Pro for unlimited habits")
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
                .stroke((isAtLimit ? Color.orange : Color.blue).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HabitsRoot()
}
