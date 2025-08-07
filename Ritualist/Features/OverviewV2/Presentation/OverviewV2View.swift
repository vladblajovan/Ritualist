import SwiftUI
import FactoryKit

public struct OverviewV2View: View {
    @ObservedObject var vm: OverviewV2ViewModel
    
    public init(vm: OverviewV2ViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: CardDesign.cardSpacing) {
                // Always show core cards
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
                
                // Floating inspiration card (right after Today's Progress)
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
                
                // Conditional cards based on user state
                if vm.shouldShowQuickActions {
                    QuickActionsCard(
                        incompleteHabits: vm.incompleteHabits,
                        currentSlogan: vm.currentSlogan,
                        timeOfDay: vm.currentTimeOfDay,
                        completionPercentage: vm.todaysSummary?.completionPercentage ?? 0.0,
                        onHabitComplete: { habit in
                            Task {
                                await vm.completeHabit(habit)
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
                
                // Smart contextual insights
                if vm.shouldShowInsights {
                    SmartInsightsCard(insights: vm.smartInsights)
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
    }
}

#Preview {
    let vm = OverviewV2ViewModel()
    return OverviewV2View(vm: vm)
}