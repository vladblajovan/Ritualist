import SwiftUI
import Combine

public struct OverviewRoot: View {
    private let factory: OverviewFactory?

    public init(factory: OverviewFactory? = nil) {
        self.factory = factory
    }

    public var body: some View {
        OverviewContentView(factory: factory)
            .navigationTitle(Strings.App.name)
            .navigationBarTitleDisplayMode(.large)
    }
}

private struct OverviewContentView: View {
    @Environment(\.appContainer) private var di
    @State private var vm: OverviewViewModel?
    @State private var isInitializing = true

    private let factory: OverviewFactory?

    init(factory: OverviewFactory?) {
        self.factory = factory
    }

    var body: some View {
        Group {
            if isInitializing {
                ProgressView(Strings.Loading.initializing)
            } else if let vm = vm {
                OverviewListView(vm: vm)
            } else {
                ErrorView(
                    title: Strings.Error.failedInitialize,
                    message: Strings.Error.unableSetupOverview
                ) {
                    await initializeAndLoad()
                }
            }
        }
        .task {
            await initializeAndLoad()
        }
    }

    @MainActor
    private func initializeAndLoad() async {
        let actualFactory = factory ?? OverviewFactory(container: di)
        vm = actualFactory.makeViewModel()
        await vm?.load()
        isInitializing = false
    }
}

private struct OverviewListView: View {
    @Environment(\.appContainer) private var di
    @Bindable var vm: OverviewViewModel
    @State private var showingAddHabit = false
    @State private var paywallItem: PaywallItem?
    @State private var tipsVM: TipsViewModel?
    
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
            } else if vm.habits.isEmpty {
                ContentUnavailableView(
                    Strings.EmptyState.noActiveHabits,
                    systemImage: "checklist",
                    description: Text(Strings.EmptyState.createHabitsToStart)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        // Slogan text
                        Text(vm.currentSlogan)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Spacing.large)
                            .padding(.top, Spacing.small)
                        
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            HStack {
                                Text(Strings.Overview.yourHabits)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button {
                                    handleCreateHabitTap()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(AppColors.brand)
                                }
                                .accessibilityLabel(Strings.Accessibility.addHabit)
                            }
                            .padding(.horizontal, Spacing.large)
                            
                            HorizontalCarousel(
                                items: vm.habits,
                                selectedItem: vm.selectedHabit,
                                onItemTap: { habit in
                                    await vm.selectHabit(habit)
                                },
                                showPageIndicator: false
                            ) { habit, isSelected in
                                Chip(
                                    text: habit.name,
                                    emoji: habit.emoji ?? "•",
                                    color: Color(hex: habit.colorHex) ?? AppColors.brand,
                                    isSelected: isSelected
                                )
                            }
                        }
                        
                        // Calendar view
                        if let selectedHabit = vm.selectedHabit {
                            VStack(alignment: .leading, spacing: Spacing.large) {
                                Text(Strings.Overview.calendar)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, Spacing.large)
                                
                                MonthlyCalendarView(
                                    selectedHabit: selectedHabit,
                                    currentMonth: vm.currentMonth,
                                    fullCalendarDays: vm.fullCalendarDays,
                                    loggedDates: vm.loggedDates,
                                    isLoggingDate: vm.isLoggingDate,
                                    isViewingCurrentMonth: vm.isViewingCurrentMonth,
                                    getHabitValueForDate: vm.getHabitValueForDate,
                                    isDateSchedulable: vm.isDateSchedulable,
                                    isWeeklyTargetMet: vm.isWeeklyTargetMet,
                                    onMonthChange: { direction in
                                        await vm.navigateToMonth(direction)
                                    },
                                    onDateTap: { date in
                                        await vm.incrementHabitForDate(date)
                                    },
                                    onTodayTap: {
                                        await vm.navigateToToday()
                                    }
                                )
                            }
                        }
                        
                        // Streak information for selected habit (premium feature)
                        if let selectedHabit = vm.selectedHabit {
                            if vm.hasAdvancedAnalytics {
                                StreakInfoView(
                                    habit: selectedHabit,
                                    currentStreak: vm.currentStreak,
                                    bestStreak: vm.bestStreak,
                                    isLoading: vm.isLoadingStreaks,
                                    shouldAnimateBestStreak: vm.shouldAnimateBestStreak,
                                    onAnimationComplete: {
                                        vm.resetBestStreakAnimation()
                                    }
                                )
                            } else {
                                // Show paywall prompt for stats (without header when locked)
                                VStack(spacing: Spacing.medium) {
                                    Button {
                                        Task { @MainActor in
                                            let factory = PaywallFactory(container: di)
                                            let viewModel = factory.makeViewModel()
                                            await viewModel.load()
                                            paywallItem = PaywallItem(viewModel: viewModel)
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                                                HStack(spacing: Spacing.xxsmall) {
                                                    Text(Strings.Paywall.unlockAdvancedStats)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                    
                                                    Image(systemName: "lock.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Text(vm.getStatsBlockedMessage())
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(Strings.Paywall.proLabel)
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, Spacing.small)
                                                .padding(.vertical, Spacing.xxsmall)
                                                .background(
                                                    Capsule()
                                                        .fill(AppColors.brand)
                                                )
                                        }
                                        .padding(Spacing.medium)
                                        .background(
                                            RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                                                .fill(Color(.systemGray6))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, Spacing.large)
                                }
                            }
                        } else {
                            // Empty state when no habit is selected
                            VStack(spacing: Spacing.medium) {
                                Text(Strings.EmptyState.noHabitSelected)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, Spacing.large)
                                
                                Text(Strings.EmptyState.tapHabitToView)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, Spacing.large)
                            }
                        }
                        
                        // Tips carousel
                        if let tipsVM = tipsVM {
                            TipsCarouselView(
                                tips: tipsVM.featuredTips,
                                isLoading: tipsVM.isLoading,
                                onTipTap: { tip in
                                    tipsVM.selectTip(tip)
                                },
                                onShowMoreTap: {
                                    tipsVM.showAllTipsSheet()
                                }
                            )
                        }
                        
                        // Bottom spacing
                        Spacer(minLength: 20)
                    }
                }
                .refreshable {
                    await vm.load()
                }
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            let detailFactory = HabitDetailFactory(container: di)
            let detailVM = detailFactory.makeViewModel(for: nil)
            HabitDetailView(vm: detailVM)
                .onDisappear {
                    Task {
                        await vm.load()
                    }
                }
        }
        .sheet(item: $paywallItem) { item in
            PaywallView(vm: item.viewModel)
        }
        .sheet(isPresented: Binding(
            get: { tipsVM?.showingAllTipsSheet ?? false },
            set: { _ in tipsVM?.hideAllTipsSheet() }
        )) {
            if let tipsVM = tipsVM {
                TipsBottomSheet(
                    tips: tipsVM.tipsForBottomSheet,
                    onTipTap: { tip in
                        // This is still needed for any external tip tapping (like from carousel)
                        tipsVM.selectTip(tip)
                    },
                    onDismiss: {
                        tipsVM.hideAllTipsSheet()
                    }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { tipsVM?.showingTipDetail ?? false },
            set: { _ in tipsVM?.hideTipDetail() }
        )) {
            if let tipsVM = tipsVM, let selectedTip = tipsVM.selectedTip {
                TipDetailView(
                    tip: selectedTip,
                    onDismiss: {
                        tipsVM.hideTipDetail()
                    }
                )
            }
        }
        .task {
            // Initialize tips view model when the view appears
            if tipsVM == nil {
                let tipsFactory = TipsFactory(container: di)
                tipsVM = tipsFactory.makeViewModel()
                await tipsVM?.load()
            }
        }
    }
    
    // MARK: - Paywall Protection Methods
    
    private func handleCreateHabitTap() {
        // Check if user can create more habits
        if vm.canCreateMoreHabits {
            showingAddHabit = true
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
}

#Preview {
    let container = DefaultAppContainer.createMinimal()
    return OverviewRoot(factory: OverviewFactory(container: container))
        .environment(\.appContainer, container)
}
