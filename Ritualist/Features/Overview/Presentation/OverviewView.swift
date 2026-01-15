import SwiftUI
import FactoryKit
import RitualistCore

public struct OverviewView: View {
    @State var vm: OverviewViewModel
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Injected(\.navigationService) private var navigationService
    @Injected(\.paywallViewModel) private var paywallViewModel
    
    @State private var habitLimitPaywallItem: PaywallItem?
    
    public init(vm: OverviewViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            stickyBrandHeader
            scrollContent
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Scroll Content
    
    @ViewBuilder
    private var scrollContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                cardContent(proxy: proxy)
            }
            .refreshable {
                await vm.refresh()
            }
            .task {
                await vm.loadData()
            }
            .modifier(OverviewLifecycleModifier(vm: vm, onAppear: {
                processNumericHabitWithViewStateValidation()
                processBinaryHabitWithViewStateValidation()
            }))
            .modifier(OverviewNotificationModifier(vm: vm))
            .modifier(OverviewSheetModifier(
                vm: vm,
                habitLimitPaywallItem: $habitLimitPaywallItem
            ))
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Card Content
    
    @ViewBuilder
    private func cardContent(proxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: CardDesign.cardSpacing) {
            inspirationSection
            habitLimitBannerSection
            todaysSummarySection
            calendarSection(proxy: proxy)
            personalitySection
            Spacer(minLength: 100)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.top, 16)
        .id("scrollTop")
    }
    
    // MARK: - Inspiration Section
    
    @ViewBuilder
    private var inspirationSection: some View {
        if vm.shouldShowInspirationCard && !vm.inspirationItems.isEmpty {
            InspirationCarouselView(
                items: vm.inspirationItems,
                timeOfDay: vm.currentTimeOfDay,
                completionPercentage: vm.todaysSummary?.completionPercentage ?? 0.0,
                onDismiss: { item in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        vm.dismissInspirationItem(item)
                    }
                },
                onDismissAll: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        vm.dismissAllInspirationItems()
                    }
                }
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    // MARK: - Habit Limit Banner Section
    
    @ViewBuilder
    private var habitLimitBannerSection: some View {
        if vm.showDeactivateHabitsBanner {
            DeactivateHabitsPromptBanner(
                activeCount: vm.activeHabitsCount,
                maxFreeHabits: BusinessConstants.freeMaxHabits,
                onManageHabits: {
                    navigationService.navigateToHabits()
                },
                onUpgrade: {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await paywallViewModel.load()
                        paywallViewModel.trackPaywallShown(source: "overview", trigger: "habit_limit_banner")
                        habitLimitPaywallItem = PaywallItem(viewModel: paywallViewModel)
                    }
                }
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    // MARK: - Today's Summary Section
    
    @ViewBuilder
    private var todaysSummarySection: some View {
        TodaysSummaryCard(
            summary: vm.todaysSummary,
            viewingDate: vm.viewingDate,
            isViewingToday: vm.isViewingToday,
            timezone: vm.displayTimezone,
            canGoToPrevious: vm.canGoToPreviousDay,
            canGoToNext: vm.canGoToNextDay,
            weeklyData: vm.monthlyCompletionData,
            currentSlogan: vm.isViewingToday ? vm.currentSlogan : nil,
            onQuickAction: { habit in
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await vm.completeHabit(habit)
                }
            },
            onNumericHabitUpdate: { habit, newValue in
                try await vm.updateNumericHabit(habit, value: newValue)
            },
            getProgressSync: { habit in
                vm.getProgressSync(for: habit)
            },
            onNumericHabitAction: { habit in
                vm.showNumericSheet(for: habit)
            },
            onBinaryHabitAction: { habit in
                vm.showBinarySheet(for: habit)
            },
            onLongPressComplete: { habit in
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    if habit.kind == .binary {
                        await vm.completeHabit(habit)
                    } else {
                        let targetValue = habit.dailyTarget ?? 1.0
                        try? await vm.updateNumericHabit(habit, value: targetValue)
                    }
                }
            },
            onDeleteHabitLog: { habit in
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await vm.deleteHabitLog(habit)
                }
            },
            getScheduleStatus: { habit in
                vm.getScheduleStatus(for: habit)
            },
            getValidationMessage: { habit in
                await vm.getScheduleValidationMessage(for: habit)
            },
            getStreakStatus: { habit in
                vm.getStreakStatusSync(for: habit)
            },
            onPreviousDay: {
                vm.goToPreviousDay()
            },
            onNextDay: {
                vm.goToNextDay()
            },
            onGoToToday: {
                vm.goToToday()
            },
            isLoggingLocked: vm.showDeactivateHabitsBanner
        )
        .cardStyle()
    }
    
    // MARK: - Calendar Section
    
    @ViewBuilder
    private func calendarSection(proxy: ScrollViewProxy) -> some View {
        if vm.shouldShowActiveStreaks || vm.isLoading {
            calendarWithStreaks(proxy: proxy)
        } else {
            calendarOnly(proxy: proxy)
        }
    }
    
    @ViewBuilder
    private func calendarWithStreaks(proxy: ScrollViewProxy) -> some View {
        EqualHeightRow {
            StreaksCard(
                streaks: vm.activeStreaks,
                shouldAnimateBestStreak: false,
                onAnimationComplete: {},
                isLoading: vm.isLoading
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .cardStyle()
        } second: {
            MonthlyCalendarCard(
                monthlyData: vm.monthlyCompletionData,
                onDateSelect: { date in
                    vm.goToDate(date)
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo("scrollTop", anchor: .top)
                        }
                    }
                },
                timezone: vm.displayTimezone,
                selectedDate: vm.viewingDate
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .cardStyle()
        }
    }
    
    @ViewBuilder
    private func calendarOnly(proxy: ScrollViewProxy) -> some View {
        MonthlyCalendarCard(
            monthlyData: vm.monthlyCompletionData,
            onDateSelect: { date in
                vm.goToDate(date)
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo("scrollTop", anchor: .top)
                    }
                }
            },
            timezone: vm.displayTimezone,
            selectedDate: vm.viewingDate
        )
        .cardStyle()
    }
    
    // MARK: - Personality Section
    
    @ViewBuilder
    private var personalitySection: some View {
        if vm.shouldShowPersonalityInsights {
            PersonalityInsightsCard(
                insights: vm.personalityInsights,
                dominantTrait: vm.dominantPersonalityTrait,
                isDataSufficient: vm.isPersonalityDataSufficient,
                thresholdRequirements: vm.personalityThresholdRequirements,
                onOpenAnalysis: {
                    vm.openPersonalityAnalysis()
                }
            )
            .cardStyle()
        } else if vm.showPersonalityUpsell {
            PersonalityInsightsUpsellCard(
                onUnlock: {
                    vm.showPersonalityPaywall()
                }
            )
            .cardStyle()
        }
    }
    
    // MARK: - Brand Header
    
    @ViewBuilder
    private var stickyBrandHeader: some View {
        AppBrandHeader(
            completionPercentage: vm.todaysSummary?.completionPercentage,
            progressDisplayStyle: .circular,
            showAvatarTip: true
        )
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.medium + (horizontalSizeClass == .regular ? 10 : 0))
        .background(Color(.systemGroupedBackground))
        .zIndex(1)
    }
    
    // MARK: - Private Methods
    
    private func processNumericHabitWithViewStateValidation() {
        guard vm.pendingNumericHabitFromNotification != nil && !vm.isPendingHabitProcessed else {
            return
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            
            if isViewReadyForSheetPresentation() {
                vm.processPendingNumericHabit()
            } else {
                try? await Task.sleep(for: .milliseconds(500))
                vm.processPendingNumericHabit()
            }
        }
    }
    
    private func isViewReadyForSheetPresentation() -> Bool {
        let hasDataLoaded = vm.todaysSummary != nil
        let noConflictingSheet = !vm.showingNumericSheet && !vm.showingCompleteHabitSheet && vm.selectedHabitForSheet == nil
        return hasDataLoaded && noConflictingSheet
    }
    
    private func processBinaryHabitWithViewStateValidation() {
        guard vm.pendingBinaryHabitFromNotification != nil && !vm.isPendingBinaryHabitProcessed else {
            return
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            
            if isViewReadyForSheetPresentation() {
                vm.processPendingBinaryHabit()
            } else {
                try? await Task.sleep(for: .milliseconds(500))
                vm.processPendingBinaryHabit()
            }
        }
    }
}

// MARK: - Lifecycle Modifier

private struct OverviewLifecycleModifier: ViewModifier {
    let vm: OverviewViewModel
    let onAppear: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: vm.isMigrating) { wasMigrating, isMigrating in
                if wasMigrating && !isMigrating {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.refresh()
                    }
                }
            }
            .onAppear {
                vm.setViewVisible(true)
                onAppear()
            }
            .onDisappear {
                vm.setViewVisible(false)
                vm.markViewDisappeared()
            }
            .onChange(of: vm.isViewVisible) { wasVisible, isVisible in
                if !wasVisible && isVisible && vm.isReturningFromTabSwitch {
                    vm.hidePersonalityUpsell()
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        Container.shared.debugLogger().log("Tab switch detected: Reloading overview data", level: .debug, category: .ui)
                        vm.invalidateCacheForTabSwitch()
                        await vm.refresh()
                        await vm.refreshPersonalityInsights()
                    }
                }
            }
    }
}

// MARK: - Notification Modifier

private struct OverviewNotificationModifier: ViewModifier {
    let vm: OverviewViewModel
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await vm.refresh()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    Container.shared.debugLogger().log(
                        "☁️ iCloud sync detected - refreshing Overview",
                        level: .info,
                        category: .system
                    )
                    await vm.refresh()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .habitsDataDidChange)) { _ in
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await vm.refresh()
                }
            }
    }
}

// MARK: - Sheet Modifier

private struct OverviewSheetModifier: ViewModifier {
    let vm: OverviewViewModel
    @Binding var habitLimitPaywallItem: PaywallItem?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: .init(
                get: { vm.showingNumericSheet },
                set: { vm.showingNumericSheet = $0 }
            )) {
                numericSheetContent
            }
            .sheet(isPresented: .init(
                get: { vm.showingCompleteHabitSheet },
                set: { vm.showingCompleteHabitSheet = $0 }
            )) {
                binarySheetContent
            }
            .sheet(item: .init(
                get: { vm.personalityPaywallItem },
                set: { vm.personalityPaywallItem = $0 }
            )) { item in
                PaywallView(vm: item.viewModel)
            }
            .onChange(of: vm.personalityPaywallItem) { oldValue, newValue in
                if oldValue != nil && newValue == nil {
                    vm.handlePersonalityPaywallDismissal()
                }
            }
            .sheet(item: $habitLimitPaywallItem) { item in
                PaywallView(vm: item.viewModel)
            }
            .onChange(of: habitLimitPaywallItem) { oldValue, newValue in
                if oldValue != nil && newValue == nil {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.refresh()
                    }
                }
            }
    }
    
    @ViewBuilder
    private var numericSheetContent: some View {
        if let habit = vm.selectedHabitForSheet, habit.kind == .numeric {
            NumericHabitLogSheetDirect(
                habit: habit,
                viewingDate: vm.viewingDate,
                timezone: vm.displayTimezone,
                onSave: { newValue in
                    try await vm.updateNumericHabit(habit, value: newValue)
                },
                onCancel: { },
                initialValue: vm.getProgressSync(for: habit)
            )
        }
    }
    
    @ViewBuilder
    private var binarySheetContent: some View {
        if let habit = vm.selectedHabitForSheet, habit.kind == .binary {
            CompleteHabitSheet(
                habit: habit,
                onComplete: {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.completeHabit(habit)
                    }
                },
                onCancel: { }
            )
        }
    }
}

#Preview {
    let vm = OverviewViewModel()
    return OverviewView(vm: vm)
}
