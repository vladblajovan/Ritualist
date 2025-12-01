import SwiftUI
import FactoryKit
import RitualistCore

public struct OverviewView: View {
    @State var vm: OverviewViewModel

    public init(vm: OverviewViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: CardDesign.cardSpacing) {
                // Always show core cards
                // Inspiration carousel moved to top position
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
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                TodaysSummaryCard(
                    summary: vm.todaysSummary,
                    viewingDate: vm.viewingDate,
                    isViewingToday: vm.isViewingToday,
                    canGoToPrevious: vm.canGoToPreviousDay,
                    canGoToNext: vm.canGoToNextDay,
                    currentSlogan: vm.isViewingToday ? vm.currentSlogan : nil,
                    onQuickAction: { habit in
                        Task {
                            await vm.completeHabit(habit)
                        }
                    },
                    onNumericHabitUpdate: { habit, newValue in
                        await vm.updateNumericHabit(habit, value: newValue)
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
                // PERFORMANCE: Use simpleCard instead of glassmorphicCard for this massive 932-line card
                // .thinMaterial blur recalculates on every scroll frame = expensive for complex content
                .simpleCard()
                .id("topCard")
                
                // Conditional cards based on user state
                // COMMENTED OUT: QuickActionsCard - Quick Log functionality temporarily disabled
                /*
                if vm.shouldShowQuickActions {
                    QuickActionsCard(
                        incompleteHabits: vm.incompleteHabits,
                        completedHabits: vm.completedHabits,
                        currentSlogan: vm.currentSlogan,
                        timeOfDay: vm.currentTimeOfDay,
                        completionPercentage: vm.todaysSummary?.completionPercentage ?? 0.0,
                        viewingDate: vm.viewingDate,
                        onHabitComplete: { habit in
                            Task {
                                await vm.completeHabit(habit)
                            }
                        },
                        getProgressSync: { habit in
                            vm.getProgressSync(for: habit)
                        },
                        onNumericHabitUpdate: { habit, newValue in
                            Task {
                                await vm.updateNumericHabit(habit, value: newValue)
                            }
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
                        getWeeklyProgress: { habit in
                            vm.getWeeklyProgress(for: habit)
                        }
                    )
                    .glassmorphicCard()
                }
                */
                
                // Monthly calendar section - heavily optimized for scroll performance
                MonthlyCalendarCard(
                    monthlyData: vm.monthlyCompletionData,
                    onDateSelect: { date in
                        vm.goToDate(date)
                        // Scroll immediately after date selection (which happens after glow effect)
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo("topCard", anchor: .top)
                        }
                    }
                )
                .simpleCard()
                
                if vm.shouldShowActiveStreaks || vm.isLoading {
                    StreaksCard(
                        streaks: vm.activeStreaks,
                        shouldAnimateBestStreak: false,
                        onAnimationComplete: {},
                        isLoading: vm.isLoading
                    )
                    .simpleCard()
                }
                
                // Smart contextual insights (basic habit patterns)
                if vm.shouldShowInsights {
                    SmartInsightsCard(insights: vm.smartInsights)
                        .simpleCard()
                }
                
                // Personality-based insights (separate card)
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
                    .simpleCard()
                }
                
                Spacer(minLength: 100) // Tab bar padding
            }
            .padding(.horizontal, Spacing.screenMargin)
            }
            .refreshable {
                await vm.refresh()
            }
            .task {
                await vm.loadData()
            }
            .onChange(of: vm.isMigrating) { wasMigrating, isMigrating in
                // When migration completes, reload data immediately
                if wasMigrating && !isMigrating {
                    Task {
                        await vm.refresh()
                    }
                }
            }
            .onAppear {
                // RACE CONDITION FIX: Set view as visible immediately
                vm.setViewVisible(true)

                // Process pending numeric habit from notification with enhanced timing validation
                // This now serves as a fallback since the observer pattern will catch most cases
                processNumericHabitWithViewStateValidation()
            }
            .onDisappear {
                // RACE CONDITION FIX: Set view as not visible
                vm.setViewVisible(false)
                // Track that view has disappeared (for tab switch detection)
                vm.markViewDisappeared()
            }
            .onChange(of: vm.isViewVisible) { wasVisible, isVisible in
                // When view becomes visible (tab switch), reload to pick up changes from other tabs
                // This ensures habit schedule changes from Habits screen are reflected in Overview
                //
                // IMPORTANT: Skip on initial appear - the .task modifier handles initial load.
                // Only reload when returning to this tab after visiting another tab.
                // We use isReturningFromTabSwitch which tracks if onDisappear was ever called,
                // correctly distinguishing initial appear from tab switch regardless of load success.
                if !wasVisible && isVisible && vm.isReturningFromTabSwitch {
                    Task {
                        Container.shared.debugLogger().log("Tab switch detected: Reloading overview data", level: .debug, category: .ui)
                        vm.invalidateCacheForTabSwitch()
                        // Use refresh() to bypass the "already loaded" check
                        await vm.refresh()
                        await vm.refreshPersonalityInsights()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh data when app comes to foreground (after background notification actions)
                Task {
                    await vm.refresh()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                // Auto-refresh when iCloud syncs new data from another device
                // This ensures Overview shows the latest data without requiring tab switch
                Task {
                    Container.shared.debugLogger().log(
                        "☁️ iCloud sync detected - refreshing Overview",
                        level: .info,
                        category: .system
                    )
                    await vm.refresh()
                }
            }
            .sheet(isPresented: $vm.showingNumericSheet) {
                if let habit = vm.selectedHabitForSheet, habit.kind == .numeric {
                    NumericHabitLogSheetDirect(
                        habit: habit,
                        viewingDate: vm.viewingDate,
                        onSave: { newValue in
                            await vm.updateNumericHabit(habit, value: newValue)
                        },
                        onCancel: {
                            // Sheet dismisses automatically
                        },
                        initialValue: vm.getProgressSync(for: habit)
                    )
                }
            }
            .background(Color(.systemGroupedBackground))
        } // ScrollViewReader
    }
    
    // MARK: - Private Methods
    
    /// Processes pending numeric habit with robust view state validation and timing
    private func processNumericHabitWithViewStateValidation() {
        // PHASE 1 FIX: Guard early - only proceed if there's actually a pending habit
        guard vm.pendingNumericHabitFromNotification != nil && !vm.isPendingHabitProcessed else {
            return
        }
        
        // First attempt with 500ms delay for view hierarchy readiness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            // Validate view is ready for sheet presentation
            if isViewReadyForSheetPresentation() {
                vm.processPendingNumericHabit()
            } else {
                // PHASE 1 FIX: Normal data loading timing, not an error
                // Wait for data loading to complete (typically takes 500-1000ms)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isViewReadyForSheetPresentation() {
                        vm.processPendingNumericHabit()
                    } else {
                        // Processing anyway to prevent hanging deep links
                        vm.processPendingNumericHabit()
                    }
                }
            }
        }
    }
    
    /// Validates that the view is in a state ready for sheet presentation
    private func isViewReadyForSheetPresentation() -> Bool {
        // Check if view has basic data loaded (indicates view lifecycle is complete)
        let hasDataLoaded = vm.todaysSummary != nil
        
        // Check if there's no conflicting sheet state
        let noConflictingSheet = !vm.showingNumericSheet && vm.selectedHabitForSheet == nil
        
        // PHASE 1 FIX: Remove hasPendingHabit requirement - view can be ready without pending actions
        // The early guard in processNumericHabitWithViewStateValidation() handles the pending habit check
        return hasDataLoaded && noConflictingSheet
    }
}

#Preview {
    let vm = OverviewViewModel()
    return OverviewView(vm: vm)
}
