import SwiftUI
import Charts
import RitualistCore
import FactoryKit

// swiftlint:disable type_body_length
public struct StatsView: View {
    @Bindable var vm: StatsViewModel
    @Injected(\.debugLogger) private var logger
    @Injected(\.navigationService) private var navigationService

    @State private var showingProgressTrendInfo = false
    @State private var showingHabitPatternsInfo = false

    public init(vm: StatsViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
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
                } else {
                    emptyStateView
                }

                Spacer(minLength: 100) // Bottom padding for tab bar
            }
            .padding(.horizontal, Spacing.large)
        }
        .refreshable {
            await vm.refresh()
        }
        .navigationTitle(Strings.Navigation.stats)
        .navigationBarTitleDisplayMode(.large)
        .task {
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
                Task {
                    logger.log("Tab switch detected: Reloading dashboard data", level: .debug, category: .ui)
                    vm.invalidateCacheForTabSwitch()
                    await vm.refresh()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
            // Auto-refresh when iCloud syncs new data from another device
            Task {
                logger.log(
                    "☁️ iCloud sync detected - refreshing Dashboard",
                    level: .info,
                    category: .system
                )
                await vm.refresh()
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingProgressTrendInfo) {
            ChartInfoSheet(
                title: "Progress Trend",
                icon: "chart.line.uptrend.xyaxis",
                description: "Shows your daily habit completion rate over time.",
                details: [
                    "Each point represents your completion percentage for a specific date",
                    "The line shows how your performance changes day by day",
                    "Use this to spot trends - are you improving or declining over time?"
                ],
                example: "If you completed 3 of 5 habits on Dec 20, that day shows as 60%"
            )
        }
        .sheet(isPresented: $showingHabitPatternsInfo) {
            ChartInfoSheet(
                title: "Habit Patterns",
                icon: "chart.bar.fill",
                description: "Shows your average performance for each day of the week.",
                details: [
                    "Each bar represents your average completion rate for that weekday",
                    "Data is aggregated across the selected time period",
                    "Helps identify which days you perform best or struggle most"
                ],
                example: "If Wednesday shows 80%, it means across all Wednesdays in the period, you averaged 80% completion"
            )
        }
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
            Text("Loading analytics...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(minHeight: 200)
    }

    @ViewBuilder
    private var emptyStateView: some View {
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
    
    @ViewBuilder
    private func progressChartSection(data: [StatsViewModel.ChartDataPointViewModel]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            progressChartHeader
            progressChart(data: data)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var progressChartHeader: some View {
        HStack(alignment: .top) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(AppColors.brand)
            Text("Progress Trend")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button { showingProgressTrendInfo = true } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("About Progress Trend")
        }
    }

    @ViewBuilder
    private func progressChart(data: [StatsViewModel.ChartDataPointViewModel]) -> some View {
        Chart(data) { point in
            LineMark(x: .value("Date", point.date), y: .value("Completion", point.completionRate))
                .foregroundStyle(AppColors.brand)
                .interpolationMethod(.catmullRom)
            AreaMark(x: .value("Date", point.date), y: .value("Completion", point.completionRate))
                .foregroundStyle(GradientTokens.chartAreaFill)
                .interpolationMethod(.catmullRom)
        }
        .frame(minHeight: 200)
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue * 100))%").font(.caption2)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel(format: .dateTime.month().day()).font(.caption2)
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress trend chart")
        .accessibilityValue(chartAccessibilityDescription(data: data))
    }

    private func chartAccessibilityDescription(data: [StatsViewModel.ChartDataPointViewModel]) -> String {
        guard !data.isEmpty else { return Strings.Accessibility.chartNoData }
        let avgCompletion = data.map { $0.completionRate }.reduce(0, +) / Double(data.count)
        let firstRate = data.first?.completionRate ?? 0
        let lastRate = data.last?.completionRate ?? 0
        let trend = data.count > 1 && lastRate > firstRate ? "improving" : "declining"
        return Strings.Accessibility.chartDescription(avgCompletion: Int(avgCompletion * 100), trend: trend)
    }
    
    @ViewBuilder
    private func weeklyPatternsSection(patterns: StatsViewModel.WeeklyPatternsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.brand.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.brand)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Habit Patterns")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Understand your consistency trends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingHabitPatternsInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("About Habit Patterns")
            }

            if patterns.isDataSufficient {
                scheduleOptimizationContent(patterns: patterns)
            } else {
                thresholdRequirementsContent(requirements: patterns.thresholdRequirements)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func streakAnalysisSection(analysis: StatsViewModel.StreakAnalysisViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            streakAnalysisHeader
            streakAnalysisGrid(analysis: analysis)
            streakTrendIndicator(analysis: analysis)
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .cardStyle()
    }

    @ViewBuilder
    private var streakAnalysisHeader: some View {
        HStack {
            Image(systemName: "flame.fill").font(.title2).foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Period Streaks").font(.headline).foregroundColor(.primary)
                Text("Performance during selected period").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func streakAnalysisGrid(analysis: StatsViewModel.StreakAnalysisViewModel) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            VStack(spacing: 4) {
                Text("\(analysis.daysWithFullCompletion)").font(.title2).fontWeight(.bold).foregroundColor(.orange)
                Text("Perfect Days").font(.caption).foregroundColor(.secondary)
            }
            VStack(spacing: 4) {
                Text("\(analysis.longestStreak)").font(.title2).fontWeight(.bold).foregroundColor(.green)
                Text("Peak").font(.caption).foregroundColor(.secondary)
            }
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", analysis.consistencyScore * 100)).font(.title2).fontWeight(.bold).foregroundColor(AppColors.brand)
                Text("Consistency").font(.caption).foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func streakTrendIndicator(analysis: StatsViewModel.StreakAnalysisViewModel) -> some View {
        HStack {
            Image(systemName: analysis.streakTrend == "improving" ? "arrow.up.circle.fill" :
                  analysis.streakTrend == "declining" ? "arrow.down.circle.fill" : "minus.circle.fill")
                .foregroundColor(analysis.streakTrend == "improving" ? .green :
                               analysis.streakTrend == "declining" ? .red : .orange)
            Text("Period trend: \(analysis.streakTrend.capitalized)").font(.subheadline).foregroundColor(.primary)
            Spacer()
        }
    }

    @ViewBuilder
    private func categoryBreakdownSection(categories: [StatsViewModel.CategoryPerformanceViewModel]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            categoryBreakdownHeader
            ForEach(categories.prefix(5)) { category in
                categoryRow(category: category)
            }
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .cardStyle()
    }

    @ViewBuilder
    private var categoryBreakdownHeader: some View {
        HStack {
            Image(systemName: "square.grid.3x3.fill").font(.title2).foregroundColor(.blue)
            Text("Category Performance").font(.headline).foregroundColor(.primary)
            Spacer()
        }
    }

    @ViewBuilder
    private func categoryRow(category: StatsViewModel.CategoryPerformanceViewModel) -> some View {
        Button {
            navigationService.navigateToHabits(withCategoryId: category.id)
        } label: {
            HStack(spacing: 12) {
                categoryIndicator(category: category)
                Spacer()
                categoryProgressBar(category: category)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Accessibility.categoryLabel(
            name: category.categoryName,
            habitCount: category.habitCount,
            completionPercent: Int((category.completionRate * 100).rounded())
        ))
        .accessibilityHint("Tap to view habits in this category")
    }

    @ViewBuilder
    private func categoryIndicator(category: StatsViewModel.CategoryPerformanceViewModel) -> some View {
        HStack(spacing: 6) {
            if let emoji = category.emoji {
                Text(emoji).font(.title3).accessibilityHidden(true)
            } else {
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: category.color))
                    .frame(width: 16, height: 16).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.categoryName).font(.subheadline.weight(.medium)).foregroundColor(.primary)
                Text("\(category.habitCount) habits").font(.caption).foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func categoryProgressBar(category: StatsViewModel.CategoryPerformanceViewModel) -> some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(CardDesign.secondaryBackground).frame(width: 60, height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: CircularProgressView.adaptiveProgressColors(for: category.completionRate),
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 60 * category.completionRate, height: 8)
            }
            .accessibilityHidden(true)
            Text("\(Int((category.completionRate * 100).rounded()))%")
                .font(.subheadline.weight(.semibold)).foregroundColor(.primary).frame(minWidth: 44, alignment: .trailing)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundColor(.secondary)
        }
    }

    // MARK: - Habit Patterns Helpers

    @ViewBuilder
    private func thresholdRequirementsContent(requirements: [StatsViewModel.ThresholdRequirement]) -> some View {
        VStack(spacing: 16) {
            thresholdRequirementsHeader
            VStack(spacing: 10) {
                ForEach(Array(requirements.enumerated()), id: \.offset) { _, requirement in
                    thresholdRequirementRow(requirement: requirement)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var thresholdRequirementsHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.brand.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: "scope").font(.system(size: 18, weight: .semibold)).foregroundStyle(AppColors.brand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Building Your Profile").font(.subheadline.weight(.semibold)).foregroundColor(.primary)
                Text("Complete these to unlock insights").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func thresholdRequirementRow(requirement: StatsViewModel.ThresholdRequirement) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(requirement.isMet ? .green : .secondary)
                Text(requirement.title).font(.subheadline.weight(.medium)).foregroundColor(.primary)
                Spacer()
                Text(requirement.progressText).font(.caption.weight(.semibold))
                    .foregroundColor(requirement.isMet ? .green : AppColors.brand)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: requirement.isMet ? [.green.opacity(0.8), .green] : [AppColors.brand.opacity(0.7), AppColors.brand],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * requirement.progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func scheduleOptimizationContent(patterns: StatsViewModel.WeeklyPatternsViewModel) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                performanceSummaryRow(patterns: patterns)
                optimizationSuggestionRow(patterns: patterns)
            }
            weeklyPerformanceChart(patterns: patterns)
        }
    }

    @ViewBuilder
    private func performanceSummaryRow(patterns: StatsViewModel.WeeklyPatternsViewModel) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(patterns.isConsistentExcellence ? Color.green.opacity(0.15) : Color.yellow.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: patterns.isConsistentExcellence ? "trophy.fill" : "star.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(patterns.isConsistentExcellence ? .green : .yellow)
            }
            VStack(alignment: .leading, spacing: 2) {
                if patterns.isConsistentExcellence {
                    Text("Excellent every day").font(.subheadline.weight(.medium)).foregroundColor(.primary)
                    Text("Consistent \(Int((patterns.averageWeeklyCompletion * 100).rounded()))% completion").font(.caption).foregroundColor(.secondary)
                } else if patterns.isConsistentPerformance {
                    Text("Consistent across all days").font(.subheadline.weight(.medium)).foregroundColor(.primary)
                    Text("\(Int((patterns.averageWeeklyCompletion * 100).rounded()))% average completion").font(.caption).foregroundColor(.secondary)
                } else {
                    Text("\(patterns.bestDay) works best").font(.subheadline.weight(.medium)).foregroundColor(.primary)
                    Text("\(Int((patterns.bestDayCompletionRate * 100).rounded()))% completion rate").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func optimizationSuggestionRow(patterns: StatsViewModel.WeeklyPatternsViewModel) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(patterns.isOptimizationMeaningful ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: patterns.isOptimizationMeaningful ? "bolt.fill" : "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(patterns.isOptimizationMeaningful ? .orange : .green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(patterns.optimizationMessage).font(.subheadline.weight(.medium)).foregroundColor(.primary)
                Text(patterns.isOptimizationMeaningful ? "Consider rescheduling some habits" : "No changes needed").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func weeklyPerformanceChart(patterns: StatsViewModel.WeeklyPatternsViewModel) -> some View {
        Chart(patterns.dayOfWeekPerformance) { dayData in
            BarMark(x: .value("Day", String(dayData.dayName.prefix(3))), y: .value("Completion", dayData.completionRate))
                .foregroundStyle(LinearGradient(
                    colors: CircularProgressView.adaptiveProgressColors(for: dayData.completionRate).reversed(),
                    startPoint: .bottom, endPoint: .top
                ))
                .cornerRadius(CardDesign.innerCornerRadius / 2)
        }
        .frame(height: 100)
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue * 100))%").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.secondary.opacity(0.2))
            }
        }
        .chartXAxis {
            AxisMarks { _ in AxisValueLabel().font(.caption2).foregroundStyle(.secondary) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly performance chart")
        .accessibilityValue(weeklyChartAccessibilityValue(patterns: patterns))
    }

    private func weeklyChartAccessibilityValue(patterns: StatsViewModel.WeeklyPatternsViewModel) -> String {
        if patterns.isConsistentExcellence {
            return "Excellent consistent performance at \(Int((patterns.averageWeeklyCompletion * 100).rounded()))% completion"
        } else if patterns.isConsistentPerformance {
            return "Consistent performance at \(Int((patterns.averageWeeklyCompletion * 100).rounded()))% average completion"
        }
        return "Best day is \(patterns.bestDay) at \(Int((patterns.bestDayCompletionRate * 100).rounded()))% completion"
    }
}

// swiftlint:enable type_body_length

#Preview {
    NavigationStack {
        StatsView(vm: StatsViewModel(logger: DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "ui")))
    }
}
