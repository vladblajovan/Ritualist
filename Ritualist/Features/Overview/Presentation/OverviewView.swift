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
                .id("topCard")
                
                // Conditional cards based on user state
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
                }
                
                // Core navigation and overview
                WeeklyOverviewCard(
                    progress: vm.weeklyProgress,
                    onDateSelect: { date in
                        vm.goToDate(date)
                        // Scroll immediately after date selection (which happens after glow effect)
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo("topCard", anchor: .top)
                        }
                    }
                )
                
                // Expandable calendar section
                MonthlyCalendarCard(
                    isExpanded: $vm.isCalendarExpanded,
                    monthlyData: vm.isCalendarExpanded ? vm.monthlyCompletionData : vm.weeklyCompletionData,
                    onDateSelect: { date in
                        vm.goToDate(date)
                        // Scroll immediately after date selection (which happens after glow effect)
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo("topCard", anchor: .top)
                        }
                    }
                )
                
                if vm.shouldShowActiveStreaks || vm.isLoading {
                    StreaksCard(
                        streaks: vm.activeStreaks,
                        shouldAnimateBestStreak: false,
                        onAnimationComplete: {},
                        isLoading: vm.isLoading
                    )
                }
                
                // Smart contextual insights (basic habit patterns)
                if vm.shouldShowInsights {
                    SmartInsightsCard(insights: vm.smartInsights)
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
                }
                
                Spacer(minLength: 100) // Tab bar padding
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await vm.refresh()
        }
        .task {
            await vm.loadData()
        }
        .onAppear {
            print("[DEEP-LINK-TRACE] OverviewView.onAppear called")
            print("[DEEP-LINK-TRACE] View state: viewingDate = \(vm.viewingDate)")
            print("[DEEP-LINK-TRACE] View state: showingNumericSheet = \(vm.showingNumericSheet)")
            print("[DEEP-LINK-TRACE] View state: selectedHabitForSheet = \(vm.selectedHabitForSheet?.name ?? "nil")")
            
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
            print("[DEEP-LINK-TRACE] OverviewView.onDisappear called")
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
                .onAppear {
                    print("[DEEP-LINK-TRACE] NumericHabitLogSheetDirect appeared for habit: \(habit.name) (ID: \(habit.id))")
                    print("[DEEP-LINK-TRACE] Sheet viewingDate: \(vm.viewingDate)")
                    print("[DEEP-LINK-TRACE] Sheet initialValue: \(vm.getProgressSync(for: habit))")
                }
            }
        }
        } // ScrollViewReader
    }
    
    // MARK: - Private Methods
    
    /// Processes pending numeric habit with robust view state validation and timing
    private func processNumericHabitWithViewStateValidation() {
        print("[DEEP-LINK-TRACE] Starting enhanced numeric habit processing...")
        print("[DEEP-LINK-TRACE] Initial view state check at onAppear time:")
        print("[DEEP-LINK-TRACE] - View hierarchy ready: checking in 500ms")
        print("[DEEP-LINK-TRACE] - Current pending habit: \(vm.pendingNumericHabitFromNotification?.name ?? "none")")
        
        // First attempt with 500ms delay for view hierarchy readiness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("[DEEP-LINK-TRACE] === 500ms delay checkpoint ===")
            print("[DEEP-LINK-TRACE] View state validation:")
            print("[DEEP-LINK-TRACE] - showingNumericSheet: \(vm.showingNumericSheet)")
            print("[DEEP-LINK-TRACE] - selectedHabitForSheet: \(vm.selectedHabitForSheet?.name ?? "nil")")
            print("[DEEP-LINK-TRACE] - hasDataLoaded: \(vm.todaysSummary != nil)")
            print("[DEEP-LINK-TRACE] - pendingHabit: \(vm.pendingNumericHabitFromNotification?.name ?? "none")")
            
            // Validate view is ready for sheet presentation
            if isViewReadyForSheetPresentation() {
                print("[DEEP-LINK-TRACE] ✅ View is ready - processing pending numeric habit")
                vm.processPendingNumericHabit()
            } else {
                print("[DEEP-LINK-TRACE] ⚠️ View not ready after 500ms - attempting fallback with additional delay")
                // Fallback with longer delay if view still not ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("[DEEP-LINK-TRACE] === 1000ms fallback checkpoint ===")
                    print("[DEEP-LINK-TRACE] Fallback view state validation:")
                    print("[DEEP-LINK-TRACE] - showingNumericSheet: \(vm.showingNumericSheet)")
                    print("[DEEP-LINK-TRACE] - selectedHabitForSheet: \(vm.selectedHabitForSheet?.name ?? "nil")")
                    print("[DEEP-LINK-TRACE] - hasDataLoaded: \(vm.todaysSummary != nil)")
                    print("[DEEP-LINK-TRACE] - pendingHabit: \(vm.pendingNumericHabitFromNotification?.name ?? "none")")
                    
                    if isViewReadyForSheetPresentation() {
                        print("[DEEP-LINK-TRACE] ✅ View ready on fallback - processing pending numeric habit")
                        vm.processPendingNumericHabit()
                    } else {
                        print("[DEEP-LINK-TRACE] ❌ View still not ready after 1000ms - forcing processing anyway")
                        print("[DEEP-LINK-TRACE] This may indicate a deeper SwiftUI timing issue")
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
        
        // Check if there's actually a pending habit to process
        let hasPendingHabit = vm.pendingNumericHabitFromNotification != nil && !vm.isPendingHabitProcessed
        
        let isReady = hasDataLoaded && noConflictingSheet && hasPendingHabit
        
        print("[DEEP-LINK-TRACE] View readiness check:")
        print("[DEEP-LINK-TRACE] - hasDataLoaded: \(hasDataLoaded)")
        print("[DEEP-LINK-TRACE] - noConflictingSheet: \(noConflictingSheet)")
        print("[DEEP-LINK-TRACE] - hasPendingHabit: \(hasPendingHabit)")
        print("[DEEP-LINK-TRACE] - isReady: \(isReady)")
        
        return isReady
    }
}

#Preview {
    let vm = OverviewViewModel()
    return OverviewView(vm: vm)
}
