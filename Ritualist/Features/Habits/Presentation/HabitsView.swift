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
    @Bindable var vm: HabitsViewModel
    
    var body: some View {
        HabitsListView(vm: vm)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.handleCreateHabitTap()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppColors.brand)
                    }
                    .accessibilityLabel(Strings.Accessibility.addHabit)
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
            .onChange(of: vm.paywallItem) { oldValue, newValue in
                // When paywall item becomes nil, the sheet is dismissed
                if oldValue != nil && newValue == nil {
                    vm.handlePaywallDismissal()
                }
            }
    }
}

private struct HabitsListView: View {
    @Bindable var vm: HabitsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var habitToDelete: Habit?
    
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
                        vm.handleAssistantTap(source: "emptyState")
                    }
                }
            } else {
                VStack(spacing: 0) {
                    List {
                        ForEach(vm.items, id: \.id) { habit in
                            HabitRowView(habit: habit) {
                                vm.selectHabit(habit)
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
                        .onMove(perform: { source, destination in
                            Task {
                                await moveHabit(from: source, to: destination)
                            }
                        })
                    }
                    .refreshable {
                        await vm.load()
                    }
                    
                    VStack(spacing: 0) {
                        // Habit assistant
                        AssistantButton {
                            vm.handleAssistantTap(source: "habitsPage")
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
    
    private func deleteHabit(_ habit: Habit) async {
        _ = await vm.delete(id: habit.id)
    }
    
    private func moveHabit(from source: IndexSet, to destination: Int) async {
        var reorderedHabits = vm.items
        reorderedHabits.move(fromOffsets: source, toOffset: destination)
        _ = await vm.reorderHabits(reorderedHabits)
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
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, Spacing.small)
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
