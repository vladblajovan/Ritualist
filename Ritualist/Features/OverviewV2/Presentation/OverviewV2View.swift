import SwiftUI
import FactoryKit
import RitualistCore

public struct OverviewV2View: View {
    @ObservedObject var vm: OverviewV2ViewModel
    
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
                    getCurrentProgress: vm.getCurrentProgress,
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
                        onHabitComplete: { habit in
                            Task {
                                await vm.completeHabit(habit)
                            }
                        },
                        getCurrentProgress: { habit in
                            vm.getCurrentProgress(for: habit)
                        },
                        onNumericHabitUpdate: { habit, newValue in
                            Task {
                                await vm.updateNumericHabit(habit, value: newValue)
                            }
                        }
                    )
                }
                
                if vm.shouldShowActiveStreaks {
                    ActiveStreaksCard(streaks: vm.activeStreaks)
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
                
                // Smart contextual insights (basic habit patterns)
                if vm.shouldShowInsights {
                    SmartInsightsCard(insights: vm.smartInsights)
                }
                
                // Personality-based insights (separate card)
                if vm.shouldShowPersonalityInsights {
                    PersonalityInsightsCard(
                        insights: vm.personalityInsights,
                        dominantTrait: vm.dominantPersonalityTrait,
                        onOpenAnalysis: {
                            vm.openPersonalityAnalysis()
                        }
                    )
                }
                
                Spacer(minLength: 100) // Tab bar padding
            }
            .padding(.horizontal, 20)
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
    }
}

#Preview {
    let vm = OverviewV2ViewModel()
    return OverviewV2View(vm: vm)
}