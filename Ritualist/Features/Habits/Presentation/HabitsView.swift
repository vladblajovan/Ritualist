import SwiftUI

extension Notification.Name {
    static let habitCountChanged = Notification.Name("habitCountChanged")
}

public struct HabitsRoot: View {
    @Environment(\.appContainer) private var di
    @State private var showingCreateHabit = false
    @State private var showingHabitAssistant = false
    @State private var paywallItem: PaywallItem?
    @State private var habitCount = 0
    private let factory: HabitsFactory?
    
    public init(factory: HabitsFactory? = nil) { 
        self.factory = factory
    }
    
    public var body: some View {
        HabitsContentView(
            factory: factory, 
            showingCreateHabit: $showingCreateHabit,
            showingHabitAssistant: $showingHabitAssistant,
            onHabitCreate: createHabitFromSuggestion
        )
        .navigationTitle("Habits")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    handleCreateHabitTap()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.brand)
                }
            }
        }
        .sheet(isPresented: $showingCreateHabit) {
            let detailFactory = HabitDetailFactory(container: di)
            let detailVM = detailFactory.makeViewModel(for: nil)
            HabitDetailView(vm: detailVM)
        }
        .sheet(item: $paywallItem) { item in
            PaywallView(vm: item.viewModel)
        }
        .task {
            await loadHabitCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .habitCountChanged)) { _ in
            Task {
                await loadHabitCount()
            }
        }
    }
    
    private func createHabitFromSuggestion(_ suggestion: HabitSuggestion) async -> Bool {
        do {
            let habit = suggestion.toHabit()
            try await di.habitRepository.create(habit)
            await loadHabitCount() // Refresh count after creation
            return true
        } catch {
            return false
        }
    }
    
    private func handleCreateHabitTap() {
        // Check if user can create more habits
        if di.featureGatingService.canCreateMoreHabits(currentCount: habitCount) {
            showingCreateHabit = true
        } else {
            // Show paywall for free users who hit the limit
            Task { @MainActor in
                let factory = PaywallFactory(container: di)
                let viewModel = factory.makeViewModel()
                
                // Load data first
                await viewModel.load()
                
                // Use item-based presentation
                paywallItem = PaywallItem(viewModel: viewModel)
            }
        }
    }
    
    private func loadHabitCount() async {
        do {
            let habits = try await di.habitRepository.fetchAllHabits()
            await MainActor.run {
                habitCount = habits.count
            }
        } catch {
            // If we can't load habits, assume 0 for safety
            await MainActor.run {
                habitCount = 0
            }
        }
    }
}

private struct HabitsContentView: View {
    @Environment(\.appContainer) private var di
    @State private var vm: HabitsViewModel?
    @State private var isInitializing = true
    @Binding var showingCreateHabit: Bool
    @Binding var showingHabitAssistant: Bool
    
    private let factory: HabitsFactory?
    private let onHabitCreate: (HabitSuggestion) async -> Bool
    
    init(factory: HabitsFactory?, 
         showingCreateHabit: Binding<Bool>,
         showingHabitAssistant: Binding<Bool>,
         onHabitCreate: @escaping (HabitSuggestion) async -> Bool) {
        self.factory = factory
        self._showingCreateHabit = showingCreateHabit
        self._showingHabitAssistant = showingHabitAssistant
        self.onHabitCreate = onHabitCreate
    }
    
    var body: some View {
        Group {
            if isInitializing {
                ProgressView("Initializing...")
            } else if let vm = vm {
                HabitsListView(vm: vm, showingCreateHabit: $showingCreateHabit, showingHabitAssistant: $showingHabitAssistant)
            } else {
                ErrorView(
                    title: "Failed to Initialize",
                    message: "Unable to set up the habits screen"
                ) {
                    await initializeAndLoad()
                }
            }
        }
        .task {
            await initializeAndLoad()
        }
        .onChange(of: showingCreateHabit) { _, newValue in
            // Refresh the list when the create habit sheet is dismissed
            if !newValue {
                Task {
                    await vm?.load()
                    // Also notify parent to refresh habit count
                    NotificationCenter.default.post(name: .habitCountChanged, object: nil)
                }
            }
        }
        .onChange(of: showingHabitAssistant) { _, newValue in
            // Refresh the list when the assistant sheet is dismissed
            if !newValue {
                Task {
                    await vm?.load()
                }
            }
        }
        .sheet(isPresented: $showingHabitAssistant) {
            if let vm = vm {
                HabitAssistantSheet(
                    suggestionsService: di.habitSuggestionsService,
                    existingHabits: vm.items,
                    onHabitCreate: onHabitCreate,
                    userActionTracker: di.userActionTracker
                )
            }
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

private struct HabitsListView: View {
    @Environment(\.appContainer) private var di
    @Bindable var vm: HabitsViewModel
    @State private var selectedHabit: Habit?
    @State private var showingDeleteConfirmation = false
    @State private var habitToDelete: Habit?
    @Binding var showingCreateHabit: Bool
    @Binding var showingHabitAssistant: Bool
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView(Strings.Loading.habits)
            } else if let error = vm.error {
                ErrorView(
                    title: Strings.Error.failedLoadHabits,
                    message: error.localizedDescription
                ) {
                    await vm.retry()
                }
            } else if vm.items.isEmpty {
                VStack(spacing: Spacing.xlarge) {
                    ContentUnavailableView(
                        Strings.EmptyState.noHabitsYet,
                        systemImage: "plus.circle",
                        description: Text(Strings.EmptyState.tapPlusToCreate)
                    )
                    
                    AssistantButton {
                        di.userActionTracker.track(.habitsAssistantOpened(source: .emptyState))
                        showingHabitAssistant = true
                    }
                }
            } else {
                VStack(spacing: 0) {
                    List {
                        ForEach(vm.items, id: \.id) { habit in
                            HabitRowView(habit: habit) {
                                selectedHabit = habit
                            }
                            .swipeActions(edge: .leading) {
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
                        .onDelete(perform: { indexSet in
                            if let index = indexSet.first {
                                habitToDelete = vm.items[index]
                                showingDeleteConfirmation = true
                            }
                        })
                    }
                    .refreshable {
                        await vm.load()
                    }
                    
                    VStack(spacing: 0) {
                        // Habit assistant
                        AssistantButton {
                            di.userActionTracker.track(.habitsAssistantOpened(source: .habitsPage))
                            showingHabitAssistant = true
                        }
                        .padding(.horizontal, Spacing.large)
                        .padding(.vertical, Spacing.medium)
                    }
                    
                    Spacer()
                        .frame(height: Spacing.large)
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
        .sheet(item: $selectedHabit) { habit in
            let detailFactory = HabitDetailFactory(container: di)
            let detailVM = detailFactory.makeViewModel(for: habit)
            HabitDetailView(vm: detailVM)
                .onDisappear {
                    Task {
                        await vm.load() // Refresh the list when detail view is dismissed
                    }
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
    
    private func deleteHabit(_ habit: Habit) async {
        _ = await vm.delete(id: habit.id)
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
                Text(habit.emoji ?? "•")
                VStack(alignment: .leading) {
                    Text(habit.name).bold()
                    Text(habit.isActive ? Strings.Status.active : Strings.Status.inactive)
                        .font(.caption)
                        .foregroundColor(habit.isActive ? .green : .secondary)
                }
                Spacer()
                Circle()
                    .fill(Color(hex: habit.colorHex) ?? .blue)
                    .frame(width: ComponentSize.smallIndicator, height: ComponentSize.smallIndicator)
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
