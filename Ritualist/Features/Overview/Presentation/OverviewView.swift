import SwiftUI
import Combine
import FactoryKit
import RitualistCore

public struct OverviewRoot: View {
    @Injected(\.overviewViewModel) var vm
    @Injected(\.navigationService) var navigationService
    @State private var showingAddHabit = false
    @State private var paywallItem: PaywallItem?
    @State private var selectedHabitForEdit: Habit?
    @Injected(\.paywallViewModel) var paywallViewModel

    public init() {}

    public var body: some View {
        OverviewContentView(vm: vm, showingAddHabit: $showingAddHabit, paywallItem: $paywallItem, selectedHabitForEdit: $selectedHabitForEdit)
            .navigationTitle(Strings.App.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleCreateHabitTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                            Text("Add Habit")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(AppColors.brand)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(Strings.Accessibility.addHabit)
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                let detailVM = HabitDetailViewModel(habit: nil)
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
            .sheet(item: $selectedHabitForEdit) { habit in
                let detailVM = HabitDetailViewModel(habit: habit)
                HabitDetailView(vm: detailVM)
                    .onDisappear {
                        // Refresh data after potential habit changes
                        Task {
                            await vm.load()
                        }
                    }
            }
            .task {
                await vm.load()
            }
            .onChange(of: navigationService.shouldRefreshOverview) { _, shouldRefresh in
                if shouldRefresh {
                    Task {
                        // Small delay to ensure database transaction is complete
                        try? await Task.sleep(for: .milliseconds(100))
                        await vm.load()
                        navigationService.didRefreshOverview()
                    }
                }
            }
    }
    
    private func handleCreateHabitTap() {
        if vm.canCreateMoreHabits {
            showingAddHabit = true
        } else {
            Task {
                await paywallViewModel.load()
                paywallItem = PaywallItem(viewModel: paywallViewModel)
            }
        }
    }
}

private struct OverviewContentView: View {
    @Bindable var vm: OverviewViewModel
    @Binding var showingAddHabit: Bool
    @Binding var paywallItem: PaywallItem?
    @Binding var selectedHabitForEdit: Habit?

    var body: some View {
        OverviewListView(vm: vm, showingAddHabit: $showingAddHabit, paywallItem: $paywallItem, selectedHabitForEdit: $selectedHabitForEdit)
    }
}

private struct OverviewListView: View {
    @Bindable var vm: OverviewViewModel
    @Binding var showingAddHabit: Bool
    @Binding var paywallItem: PaywallItem?
    @Binding var selectedHabitForEdit: Habit?
    @Injected(\.tipsViewModel) var tipsVM
    @Injected(\.paywallViewModel) var paywallViewModel
    
    var body: some View {
        ScrollView {
            if vm.isLoading {
                VStack {
                    Spacer()
                    ProgressView(Strings.Loading.habits)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error {
                VStack {
                    Spacer()
                    ErrorView(
                        title: Strings.Error.failedLoadHabits,
                        message: error.localizedDescription
                    ) {
                        await vm.retry()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.habits.isEmpty {
                VStack {
                    Spacer()
                    ContentUnavailableView(
                        Strings.EmptyState.noActiveHabits,
                        systemImage: "checklist",
                        description: Text(Strings.EmptyState.createHabitsToStart)
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Slogan text
                    Text(vm.currentSlogan)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.large)
                        .padding(.top, Spacing.small)
                    
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(Strings.Overview.yourHabits)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, Spacing.large)
                        
                        HorizontalCarousel(
                            items: vm.habits,
                            selectedItem: vm.selectedHabit,
                            onItemTap: { habit in
                                await vm.selectHabit(habit)
                            },
                            onItemLongPress: { habit in
                                selectedHabitForEdit = habit
                            },
                            showPageIndicator: false
                        ) { habit, isSelected in
                            Chip(
                                text: habit.name,
                                emoji: habit.emoji ?? "•",
                                color: AppColors.brand,
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
                                },
                                onNumericHabitUpdate: { date, habit, value in
                                    await vm.updateNumericHabitForDate(date, habit: habit, value: value)
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
                                        await paywallViewModel.load()
                                        paywallItem = PaywallItem(viewModel: paywallViewModel)
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
                    
                    // Bottom spacing
                    Spacer(minLength: 20)
                }
            }
        }
        .refreshable {
            await vm.load()
        }
        .sheet(isPresented: Binding(
            get: { tipsVM.showingAllTipsSheet },
            set: { _ in tipsVM.hideAllTipsSheet() }
        )) {
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
        .sheet(isPresented: Binding(
            get: { tipsVM.showingTipDetail },
            set: { _ in tipsVM.hideTipDetail() }
        )) {
            if let selectedTip = tipsVM.selectedTip {
                TipDetailView(
                    tip: selectedTip,
                    onDismiss: {
                        tipsVM.hideTipDetail()
                    }
                )
            }
        }
        .task {
            // Load tips when the view appears
            await tipsVM.load()
        }
    }
}

#Preview {
    OverviewRoot()
}
