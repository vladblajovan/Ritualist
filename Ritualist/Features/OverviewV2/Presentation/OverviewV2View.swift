import SwiftUI
import FactoryKit
import RitualistCore

public struct OverviewV2View: View {
    @State var vm: OverviewV2ViewModel
    
    public init(vm: OverviewV2ViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
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
                        }
                    )
                }
                
                // Core navigation and overview
                WeeklyOverviewCard(progress: vm.weeklyProgress)
                
                // Expandable calendar section
                MonthlyCalendarCard(
                    isExpanded: $vm.isCalendarExpanded,
                    monthlyData: vm.isCalendarExpanded ? vm.monthlyCompletionData : vm.weeklyCompletionData,
                    onDateSelect: { date in
                        vm.selectedDate = date
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
            Task {
                await vm.refreshPersonalityInsights()
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
    }
}

#Preview {
    let vm = OverviewV2ViewModel()
    return OverviewV2View(vm: vm)
}
