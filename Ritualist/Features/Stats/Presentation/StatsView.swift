import SwiftUI
import Charts
import RitualistCore
import FactoryKit

public struct StatsView: View {
    @Bindable var vm: StatsViewModel
    @Injected(\.debugLogger) private var logger
    @Injected(\.featureGatingService) private var featureGatingService

    @State var showingProgressTrendInfo = false
    @State var showingHabitPatternsInfo = false
    @State var showingPeriodStreaksInfo = false
    @State var showingCategoryPerformanceInfo = false
    @State var isPremiumUser = false

    public init(vm: StatsViewModel) {
        self.vm = vm
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Sticky header at the top
            stickyBrandHeader

            ScrollView {
                LazyVStack(spacing: 20) {
                    // Main Stats Cards
                    if vm.hasHabits {
                    // Time Period Selector - only show when there's data to filter
                    timePeriodSelector

                    // Row 1: Habit Patterns + Progress Trend (both chart-heavy, equal heights)
                    if let weeklyPatterns = vm.weeklyPatterns,
                       let chartData = vm.progressChartData, !chartData.isEmpty {
                        EqualHeightRow {
                            weeklyPatternsSection(patterns: weeklyPatterns)
                        } second: {
                            progressChartSection(data: chartData)
                        }
                    } else {
                        // Fallback if only one card available
                        if let weeklyPatterns = vm.weeklyPatterns {
                            ReadableWidthContainer {
                                weeklyPatternsSection(patterns: weeklyPatterns)
                            }
                        }
                        if let chartData = vm.progressChartData, !chartData.isEmpty {
                            ReadableWidthContainer {
                                progressChartSection(data: chartData)
                            }
                        }
                    }

                    // Row 2: Period Streaks + Category Performance (both metric cards, equal heights)
                    // Only show Period Streaks if there's meaningful data (at least one streak or perfect day)
                    let hasStreakData = vm.streakAnalysis.map { $0.longestStreak > 0 || $0.daysWithFullCompletion > 0 } ?? false
                    let hasCategoryData = vm.categoryBreakdown.map { !$0.isEmpty } ?? false

                    if hasStreakData && hasCategoryData {
                        EqualHeightRow {
                            streakAnalysisSection(analysis: vm.streakAnalysis!)
                        } second: {
                            categoryBreakdownSection(categories: vm.categoryBreakdown!)
                        }
                    } else {
                        // Show individual cards full width when alone
                        if hasStreakData, let streakAnalysis = vm.streakAnalysis {
                            streakAnalysisSection(analysis: streakAnalysis)
                        }
                        if hasCategoryData, let categoryBreakdown = vm.categoryBreakdown {
                            categoryBreakdownSection(categories: categoryBreakdown)
                        }
                    }

                    // Row 3: Consistency Heatmap (Premium only)
                    // Re-enable at a later point when implementing as a widget
                    // if isPremiumUser {
                    //     ReadableWidthContainer {
                    //         consistencyHeatmapSection
                    //     }
                    // }
                } else {
                    emptyStateView
                }

                    Spacer(minLength: 100) // Bottom padding for tab bar
                }
                .padding(.horizontal, Spacing.large)
                .padding(.top, 8)
            }
            .refreshable {
                await vm.refresh()
                HapticFeedbackService.shared.trigger(.light)
            }
            .task {
                isPremiumUser = await featureGatingService.hasAdvancedAnalytics()
                await vm.loadData()
            }
            .onAppear {
                vm.setViewVisible(true)
            }
            .onDisappear {
                vm.setViewVisible(false)
                vm.markViewDisappeared()
            }
            .onChange(of: vm.isViewVisible) { wasVisible, isVisible in
                // When view becomes visible (tab switch), reload to pick up changes from other tabs
                // Skip on initial appear - the .task modifier handles initial load.
                if !wasVisible && isVisible && vm.isReturningFromTabSwitch {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        logger.log("Tab switch detected: Reloading dashboard data", level: .debug, category: .ui)
                        vm.invalidateCacheForTabSwitch()
                        await vm.refresh()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                // Auto-refresh when iCloud syncs new data from another device
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    logger.log(
                        "☁️ iCloud sync detected - refreshing Dashboard",
                        level: .info,
                        category: .system
                    )
                    await vm.refresh()
                }
            }
        } // VStack
        .background {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        AppColors.brand.opacity(0.25),
                        AppColors.brand.opacity(0.12),
                        AppColors.accentCyan.opacity(0.06),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)

                Color(.systemGroupedBackground)
            }
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingProgressTrendInfo) {
            ChartInfoSheet(
                title: Strings.Stats.progressTrendTitle,
                icon: "chart.line.uptrend.xyaxis",
                description: Strings.Stats.progressTrendDescription,
                details: [
                    Strings.Stats.progressTrendDetail1,
                    Strings.Stats.progressTrendDetail2,
                    Strings.Stats.progressTrendDetail3
                ],
                example: Strings.Stats.progressTrendExample
            )
        }
        .sheet(isPresented: $showingHabitPatternsInfo) {
            ChartInfoSheet(
                title: Strings.Stats.habitPatternsTitle,
                icon: "chart.bar.fill",
                description: Strings.Stats.habitPatternsDescription,
                details: [
                    Strings.Stats.habitPatternsDetail1,
                    Strings.Stats.habitPatternsDetail2,
                    Strings.Stats.habitPatternsDetail3
                ],
                example: Strings.Stats.habitPatternsExample
            )
        }
        .sheet(isPresented: $showingPeriodStreaksInfo) {
            ChartInfoSheet(
                title: Strings.Stats.periodStreaksTitle,
                icon: "flame.fill",
                description: Strings.Stats.periodStreaksDescription,
                details: [
                    Strings.Stats.periodStreaksDetail1,
                    Strings.Stats.periodStreaksDetail2,
                    Strings.Stats.periodStreaksDetail3
                ],
                example: Strings.Stats.periodStreaksExample
            )
        }
        .sheet(isPresented: $showingCategoryPerformanceInfo) {
            ChartInfoSheet(
                title: Strings.Stats.categoryPerformanceTitle,
                icon: "square.grid.3x3.fill",
                description: Strings.Stats.categoryPerformanceDescription,
                details: [
                    Strings.Stats.categoryPerformanceDetail1,
                    Strings.Stats.categoryPerformanceDetail2,
                    Strings.Stats.categoryPerformanceDetail3
                ],
                example: Strings.Stats.categoryPerformanceExample
            )
        }
    }

    // MARK: - Brand Header

    @ViewBuilder
    private var stickyBrandHeader: some View {
        AppBrandHeader(
            completionPercentage: vm.weeklyPatterns?.averageWeeklyCompletion,
            progressDisplayStyle: .circular
        )
        .padding(.top, Spacing.medium)
        .zIndex(1) // Ensure header and fade render above scroll content
    }

    // MARK: - Components

    @ViewBuilder
    private var timePeriodSelector: some View {
        // Note: .allTime excluded until performance optimization is complete
        let availablePeriods = TimePeriod.allCases.filter { $0 != .allTime }
        Picker(Strings.Dashboard.timePeriodPicker, selection: $vm.selectedTimePeriod) {
            ForEach(availablePeriods, id: \.self) { period in
                Text(period.shortDisplayName)
                    .tag(period)
                    .accessibilityLabel(period.accessibilityLabel)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(Strings.Stats.loadingAnalytics)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(minHeight: 200)
    }

    @ViewBuilder
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60)) // Keep fixed for decorative icon
                .foregroundColor(.secondary.opacity(0.6))
                .accessibilityHidden(true) // Decorative icon

            VStack(spacing: 8) {
                Text(Strings.Dashboard.noDataAvailable)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(Strings.Dashboard.startTrackingMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minHeight: 300)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Accessibility.dashboardEmptyState)
    }
}

#Preview {
    NavigationStack {
        StatsView(vm: StatsViewModel(logger: DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "ui")))
    }
}
