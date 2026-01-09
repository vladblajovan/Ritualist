import SwiftUI
import FactoryKit
import RitualistCore

public struct HabitsRoot: View {
    @Injected(\.habitsViewModel) var vm
    @Injected(\.categoryManagementViewModel) var categoryManagementVM
    @Injected(\.navigationService) private var navigationService
    @Injected(\.debugLogger) private var logger
    @State private var showingCategoryManagement = false

    public init() {}

    /// Applies pending category filter from navigation service if available
    private func applyPendingCategoryFilter() {
        if let pendingCategoryId = navigationService.consumePendingCategoryId() {
            vm.selectFilterCategoryById(pendingCategoryId)
        }
    }

    public var body: some View {
        HabitsContentView(
            vm: vm,
            showingCategoryManagement: $showingCategoryManagement
        )
        .task {
            await vm.load()
            // Apply pending category filter from navigation (e.g., from stats category tap)
            applyPendingCategoryFilter()
        }
        .onAppear {
            vm.setViewVisible(true)
            // For tab switches when data is already loaded, apply pending filter immediately
            // Skip if categories not loaded yet - .task will handle it after load
            if !vm.categories.isEmpty {
                applyPendingCategoryFilter()
            }
        }
        .onDisappear {
            vm.setViewVisible(false)
            vm.markViewDisappeared()
        }
        .onChange(of: vm.isViewVisible) { wasVisible, isVisible in
            // When view becomes visible (tab switch), reload to pick up changes from other tabs
            // Skip on initial appear - the .task modifier handles initial load.
            if !wasVisible && isVisible && vm.isReturningFromTabSwitch {
                Task {
                    logger.log("Tab switch detected: Reloading habits data", level: .debug, category: .ui)
                    vm.invalidateCacheForTabSwitch()
                    await vm.refresh()
                    // Apply pending category filter after refresh completes
                    applyPendingCategoryFilter()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
            // Don't refresh while editing - the sheet's ViewModel would be recreated
            // with stale data, causing issues like location toggle snapping back
            guard vm.selectedHabit == nil else { return }

            // Auto-refresh when iCloud syncs new data from another device
            Task {
                logger.log(
                    "☁️ iCloud sync detected - refreshing Habits list",
                    level: .info,
                    category: .system
                )
                await vm.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .habitsDataDidChange)) { _ in
            // Refresh when habits are created/updated/deleted from other screens (e.g., AI assistant)
            guard vm.selectedHabit == nil else { return }
            Task {
                await vm.refresh()
            }
        }
        .sheet(
            isPresented: $showingCategoryManagement,
            onDismiss: {
                Task {
                    await vm.refresh()
                }
            },
            content: {
                NavigationStack {
                    CategoryManagementView(vm: categoryManagementVM)
                }
            }
        )
    }
}

private struct HabitsContentView: View {
    @Environment(\.editMode) private var editMode
    @Bindable var vm: HabitsViewModel
    @Binding var showingCategoryManagement: Bool

    // Constants
    private let rightEdgeInset: CGFloat = 15

    @State private var dragOffset: CGSize

    init(vm: HabitsViewModel, showingCategoryManagement: Binding<Bool>) {
        self._vm = Bindable(wrappedValue: vm)
        self._showingCategoryManagement = showingCategoryManagement
        // Initial position: right edge with breathing room (padding + rightEdgeInset = 16 + 15 = 31)
        self._dragOffset = State(initialValue: CGSize(width: 16 + rightEdgeInset, height: 0))
    }

    private var isEditMode: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        ZStack {
            GeometryReader { _ in
                HabitsListView(
                    vm: vm,
                    showingCategoryManagement: $showingCategoryManagement
                )
                .navigationBarHidden(true)
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
                        vm.dismissAssistantAndShowPaywall()
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

    private var isEditMode: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    private var headerActions: [HeaderAction] {
        var actions: [HeaderAction] = []

        // Edit button - only show when habits exist
        if !vm.filteredHabits.isEmpty {
            actions.append(HeaderAction(
                icon: isEditMode ? "checkmark" : "pencil",
                accessibilityLabel: isEditMode ? "Done editing" : "Edit habits"
            ) {
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

    private var stickyBrandHeader: some View {
        AppBrandHeader(
            completionPercentage: nil,
            showProgressBar: false,
            actions: headerActions
        )
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.medium)
        .background(Color(.systemGroupedBackground))
        .zIndex(1)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sticky header at the top
            stickyBrandHeader

            if let error = vm.error {
                ErrorView(
                    title: Strings.Error.failedLoadHabits,
                    message: error.localizedDescription
                ) {
                    await vm.retry()
                }
            } else {
                List(selection: $selection) {
                    // Over-limit banner section
                    if vm.isOverFreeLimit {
                        OverLimitBannerView(
                            currentCount: vm.habitsData.totalHabitsCount,
                            maxCount: vm.freeMaxHabits,
                            onUpgradeTap: {
                                Task {
                                    await vm.showPaywall()
                                }
                            }
                        )
                        .padding(2) // Prevent corner clipping from List row
                        .padding(.bottom, Spacing.small * 2)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    // Categories carousel section
                    Section {
                        CategoryCarouselWithManagement(
                            categories: vm.categories,
                            selectedCategory: $vm.selectedFilterCategory,
                            onManageTap: {
                                showingCategoryManagement = true
                            },
                            scrollToStartOnSelection: false,
                            allowDeselection: true,
                            unselectedBackgroundColor: Color(.secondarySystemGroupedBackground)
                        )
                        .padding(.bottom, Spacing.large)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listSectionSpacing(0)

                    // Habits section or empty state
                    Section {
                        if vm.filteredHabits.isEmpty {
                            // Empty state content (inline, no separate carousel)
                            VStack(spacing: Spacing.xlarge) {
                                if vm.selectedFilterCategory != nil {
                                    ContentUnavailableView(
                                        "No habits in this category",
                                        systemImage: "tray",
                                        description: Text(Strings.Habits.noCategoryHabitsDescription)
                                    )
                                } else {
                                    HabitsFirstTimeEmptyState()
                                }
                            }
                            .frame(minHeight: 300)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(vm.filteredHabits, id: \.id) { habit in
                                GenericRowView.habitRowWithSchedule(
                                    habit: habit,
                                    scheduleStatus: vm.getScheduleStatus(for: habit)
                                ) {
                                    vm.selectHabit(habit)
                                }
                                .tag(habit.id)
                                .accessibilityIdentifier("habit.row.\(habit.id.uuidString)")
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
                }
                .refreshable {
                    await vm.refresh()
                }
                .onChange(of: editMode?.wrappedValue) { oldValue, newValue in
                    if oldValue == .active && newValue != .active {
                        selection.removeAll()
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.top, 16, for: .scrollContent)
                .overlay(alignment: .bottom) {
                    if !selection.isEmpty {
                        HabitsEditModeToolbar(
                            selectionCount: selection.count,
                            hasActiveSelected: hasActiveSelectedHabits,
                            hasInactiveSelected: hasInactiveSelectedHabits,
                            onActivate: {
                                Task { await activateSelectedHabits() }
                            },
                            onDeactivate: {
                                habitsToDeactivate = selection
                                showingDeactivateConfirmation = true
                            },
                            onDelete: {
                                habitsToDelete = selection
                                showingBatchDeleteConfirmation = true
                            }
                        )
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
            HabitDetailView(vm: detailVM, onDelete: {
                vm.selectedHabit = nil
                Task {
                    await vm.refresh()
                }
            })
                .onDisappear {
                    if detailVM.didMakeChanges {
                        vm.handleHabitDetailDismissal()
                    }
                }
        }
        .alert("Delete Habit", isPresented: $showingDeleteConfirmation) {
            Button(Strings.Common.delete, role: .destructive) {
                if let habit = habitToDelete {
                    Task {
                        await deleteHabit(habit)
                        habitToDelete = nil
                    }
                }
            }
            Button(Strings.Common.cancel, role: .cancel) {
                habitToDelete = nil
            }
        } message: {
            if let habit = habitToDelete {
                Text("Are you sure you want to delete \"\(habit.name)\"? This action cannot be undone and all habit data will be lost.")
            }
        }
        .alert("Delete Habits", isPresented: $showingBatchDeleteConfirmation) {
            Button(Strings.Common.delete, role: .destructive) {
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
            Button(Strings.Common.cancel, role: .cancel) { }
        } message: {
            Text(batchDeleteConfirmationMessage)
        }
        .alert("Deactivate Habits", isPresented: $showingDeactivateConfirmation) {
            Button(Strings.Common.deactivate, role: .destructive) {
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
            Button(Strings.Common.cancel, role: .cancel) { }
        } message: {
            Text(deactivateConfirmationMessage)
        }
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
            _ = await vm.toggleActiveStatus(id: habitId)
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
            _ = await vm.toggleActiveStatus(id: habitId)
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
            _ = await vm.delete(id: habitId)
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var dragOffset: CGSize
    let screenSize: CGSize
    let safeAreaInsets: EdgeInsets
    let onTap: () -> Void

    @GestureState private var temporaryOffset: CGSize = .zero
    @State private var isDragging = false

    /// Button size adapts for iPad (regular) vs iPhone (compact)
    private var buttonSize: CGFloat {
        horizontalSizeClass == .regular ? 72 : 60
    }
    private let padding: CGFloat = 16
    private let rightEdgeInset: CGFloat = 15 // Visual breathing room when snapped to right edge

    var body: some View {
        ZStack {
            // Glassmorphic background
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 4)
                .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)

            // AI icon with gradient - larger on iPad
            Image(systemName: "sparkles")
                .font(horizontalSizeClass == .regular ? .title.weight(.semibold) : .title2.weight(.semibold))
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
                            snappedWidth = -(screenSize.width - buttonSize)
                        } else {
                            snappedWidth = padding + rightEdgeInset
                        }

                        // Calculate vertical constraints
                        let buffer: CGFloat = 5
                        let maxUpwardOffset = -(screenSize.height - safeAreaInsets.top - buffer)
                        let maxDownwardOffset: CGFloat = 10

                        // Constrain height to stay between navigation and tab bar
                        let constrainedHeight = min(max(newHeight, maxUpwardOffset), maxDownwardOffset)

                        // Haptic feedback on snap
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()

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

    private var message: String {
        isAtLimit
            ? "Keep the momentum! Unlock Pro for unlimited habits."
            : "Unlock Pro to create unlimited habits and reach your goals faster."
    }

    var body: some View {
        ProUpgradeBanner(
            style: .card(habitCount: currentCount, maxHabits: maxCount, message: message),
            onUnlock: onUpgradeTap
        )
    }
}

// MARK: - First Time Empty State

private struct HabitsFirstTimeEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(Strings.EmptyState.noHabitsYet)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text("Tap")
                    Image(systemName: "plus")
                        .fontWeight(.medium)
                    Text("or")
                    Image(systemName: "sparkles")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("to create your first habit")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No habits yet. Tap plus or the AI assistant button to create your first habit.")
    }
}

#Preview {
    HabitsRoot()
}
