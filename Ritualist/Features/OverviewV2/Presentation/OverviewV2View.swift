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
                    onQuickAction: { habit in
                        Task {
                            await vm.completeHabit(habit)
                        }
                    }
                )
                
                // Conditional cards based on user state
                if vm.shouldShowQuickActions {
                    QuickActionsCard(
                        incompleteHabits: vm.incompleteHabits,
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
                    calendar: vm.calendarData,
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