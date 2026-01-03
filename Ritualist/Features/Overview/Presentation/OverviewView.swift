import SwiftUI
import FactoryKit
import RitualistCore

public struct OverviewView: View {
    @State var vm: OverviewViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(vm: OverviewViewModel) {
        self.vm = vm
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Sticky header at the top
            stickyBrandHeader

            // Scrollable content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: CardDesign.cardSpacing) {
                        
                        // Inspiration carousel at top position
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
                        
                        TodaysSummaryCard(
                            summary: vm.todaysSummary,
                            viewingDate: vm.viewingDate,
                            isViewingToday: vm.isViewingToday,
                            timezone: vm.displayTimezone,
                            canGoToPrevious: vm.canGoToPreviousDay,
                            canGoToNext: vm.canGoToNextDay,
                            currentSlogan: vm.isViewingToday ? vm.currentSlogan : nil,
                            onQuickAction: { habit in
                                Task {
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
                            onDeleteHabitLog: { habit in
                                Task {
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
                            }
                        )
                        .cardStyle()
                        
                        // Monthly Calendar + Streaks - side by side on iPad
                        if vm.shouldShowActiveStreaks || vm.isLoading {
                            EqualHeightRow {
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
                                    timezone: vm.displayTimezone
                                )
                                .frame(maxHeight: .infinity, alignment: .top)
                                .cardStyle()
                            } second: {
                                StreaksCard(
                                    streaks: vm.activeStreaks,
                                    shouldAnimateBestStreak: false,
                                    onAnimationComplete: {},
                                    isLoading: vm.isLoading
                                )
                                .frame(maxHeight: .infinity, alignment: .top)
                                .cardStyle()
                            }
                        } else {
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
                                timezone: vm.displayTimezone
                            )
                            .cardStyle()
                        }
                        
                        // Personality Insights - full width on its own row
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
                            // Upsell card for free users with sufficient data
                            PersonalityInsightsUpsellCard(
                                onUnlock: {
                                    vm.showPersonalityPaywall()
                                }
                            )
                            .cardStyle()
                        }

                        Spacer(minLength: 100) // Tab bar padding
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, 16)
                    .id("scrollTop")
                }
                .refreshable {
                    await vm.refresh()
                }
                .task {
                    await vm.loadData()
                }
                .onChange(of: vm.isMigrating) { wasMigrating, isMigrating in
                    if wasMigrating && !isMigrating {
                        Task {
                            await vm.refresh()
                        }
                    }
                }
                .onAppear {
                    vm.setViewVisible(true)
                    processNumericHabitWithViewStateValidation()
                    processBinaryHabitWithViewStateValidation()
                }
                .onDisappear {
                    vm.setViewVisible(false)
                    vm.markViewDisappeared()
                }
                .onChange(of: vm.isViewVisible) { wasVisible, isVisible in
                    if !wasVisible && isVisible && vm.isReturningFromTabSwitch {
                        // Immediately hide upsell in case user purchased from another tab
                        vm.hidePersonalityUpsell()
                        Task {
                            Container.shared.debugLogger().log("Tab switch detected: Reloading overview data", level: .debug, category: .ui)
                            vm.invalidateCacheForTabSwitch()
                            await vm.refresh()
                            await vm.refreshPersonalityInsights()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await vm.refresh()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                    Task {
                        Container.shared.debugLogger().log(
                            "☁️ iCloud sync detected - refreshing Overview",
                            level: .info,
                            category: .system
                        )
                        await vm.refresh()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .habitsDataDidChange)) { _ in
                    Task {
                        await vm.refresh()
                    }
                }
                .sheet(isPresented: $vm.showingNumericSheet) {
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
                .sheet(isPresented: $vm.showingCompleteHabitSheet) {
                    if let habit = vm.selectedHabitForSheet, habit.kind == .binary {
                        CompleteHabitSheet(
                            habit: habit,
                            onComplete: {
                                Task {
                                    await vm.completeHabit(habit)
                                }
                            },
                            onCancel: { }
                        )
                    }
                }
                .sheet(item: $vm.personalityPaywallItem) { item in
                    PaywallView(vm: item.viewModel)
                }
                .onChange(of: vm.personalityPaywallItem) { oldValue, newValue in
                    // Immediately handle dismissal when paywall closes (like HabitsView pattern)
                    if oldValue != nil && newValue == nil {
                        vm.handlePersonalityPaywallDismissal()
                    }
                }
                .background(Color(.systemGroupedBackground))
            } // ScrollViewReader
        } // VStack (sticky header + scroll content)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Brand Header
    
    @ViewBuilder
    private var stickyBrandHeader: some View {
        AppBrandHeader(
            completionPercentage: vm.todaysSummary?.completionPercentage,
            progressDisplayStyle: .circular
        )
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.medium + (horizontalSizeClass == .regular ? 10 : 0))
        .background(Color(.systemGroupedBackground))
        .zIndex(1) // Ensure header and fade render above scroll content
    }
    
    // MARK: - Private Methods
    
    /// Processes pending numeric habit with robust view state validation and timing
    private func processNumericHabitWithViewStateValidation() {
        // PHASE 1 FIX: Guard early - only proceed if there's actually a pending habit
        guard vm.pendingNumericHabitFromNotification != nil && !vm.isPendingHabitProcessed else {
            return
        }
        
        // First attempt with 500ms delay for view hierarchy readiness
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            
            // Validate view is ready for sheet presentation
            if isViewReadyForSheetPresentation() {
                vm.processPendingNumericHabit()
            } else {
                // Wait for data loading to complete (typically takes 500-1000ms)
                try? await Task.sleep(for: .milliseconds(500))
                // Processing anyway to prevent hanging deep links
                vm.processPendingNumericHabit()
            }
        }
    }
    
    /// Validates that the view is in a state ready for sheet presentation
    private func isViewReadyForSheetPresentation() -> Bool {
        // Check if view has basic data loaded (indicates view lifecycle is complete)
        let hasDataLoaded = vm.todaysSummary != nil
        
        // Check if there's no conflicting sheet state
        let noConflictingSheet = !vm.showingNumericSheet && !vm.showingCompleteHabitSheet && vm.selectedHabitForSheet == nil
        
        // PHASE 1 FIX: Remove hasPendingHabit requirement - view can be ready without pending actions
        // The early guard in processNumericHabitWithViewStateValidation() handles the pending habit check
        return hasDataLoaded && noConflictingSheet
    }
    
    /// Processes pending binary habit with robust view state validation and timing
    private func processBinaryHabitWithViewStateValidation() {
        guard vm.pendingBinaryHabitFromNotification != nil && !vm.isPendingBinaryHabitProcessed else {
            return
        }
        
        // First attempt with 500ms delay for view hierarchy readiness
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            
            if isViewReadyForSheetPresentation() {
                vm.processPendingBinaryHabit()
            } else {
                // Wait for data loading to complete
                try? await Task.sleep(for: .milliseconds(500))
                vm.processPendingBinaryHabit()
            }
        }
    }
}

#Preview {
    let vm = OverviewViewModel()
    return OverviewView(vm: vm)
}
