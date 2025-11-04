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
                // Inspiration card moved to top position
                if vm.shouldShowInspirationCard {
                    InspirationCard(
                        message: vm.currentInspirationMessage,
                        slogan: vm.currentSlogan,
                        timeOfDay: vm.currentTimeOfDay,
                        completionPercentage: vm.todaysSummary?.completionPercentage ?? 0.0,
                        shouldShow: vm.showInspirationCard,
                        onDismiss: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                vm.hideInspiration()
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
            .onAppear {
                // RACE CONDITION FIX: Set view as visible immediately
                vm.setViewVisible(true)

                Task {
                    await vm.refreshPersonalityInsights()
                }

                // Process pending numeric habit from notification with enhanced timing validation
                // This now serves as a fallback since the observer pattern will catch most cases
                processNumericHabitWithViewStateValidation()
            }
            .onDisappear {
                // RACE CONDITION FIX: Set view as not visible
                vm.setViewVisible(false)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh data when app comes to foreground (after background notification actions)
                Task {
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
            .overlay {
                // Show migration loading modal when schema migration is in progress
                if vm.isMigrating {
                    MigrationLoadingView(details: vm.migrationDetails)
                        .animation(.easeInOut(duration: 0.3), value: vm.isMigrating)
                }
            }
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
