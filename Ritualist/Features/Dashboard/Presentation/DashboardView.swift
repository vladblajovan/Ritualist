import SwiftUI
import Charts
import RitualistCore
import FactoryKit

// swiftlint:disable type_body_length
public struct DashboardView: View {
    @Bindable var vm: DashboardViewModel
    @Injected(\.debugLogger) private var logger
    @Injected(\.navigationService) private var navigationService

    public init(vm: DashboardViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Time Period Selector
                timePeriodSelector
                
                // Main Stats Cards
                if vm.hasHabits {
                    // Weekly Patterns (moved to top)
                    if let weeklyPatterns = vm.weeklyPatterns {
                        weeklyPatternsSection(patterns: weeklyPatterns)
                    }
                    
                    // Streak Analysis (moved to top)
                    if let streakAnalysis = vm.streakAnalysis {
                        streakAnalysisSection(analysis: streakAnalysis)
                    }
                    
                    // Progress Chart
                    if let chartData = vm.progressChartData, !chartData.isEmpty {
                        progressChartSection(data: chartData)
                    }
                    
                    // Category Breakdown
                    if let categoryBreakdown = vm.categoryBreakdown, !categoryBreakdown.isEmpty {
                        categoryBreakdownSection(categories: categoryBreakdown)
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
        .frame(height: 200)
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
        .frame(height: 300)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Accessibility.dashboardEmptyState)
    }
    
    @ViewBuilder
    private func progressChartSection(data: [DashboardViewModel.ChartDataPointViewModel]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(AppColors.brand)
                
                Text("Progress Trend")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Completion", point.completionRate)
                )
                .foregroundStyle(AppColors.brand)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Completion", point.completionRate)
                )
                .foregroundStyle(GradientTokens.chartAreaFill)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue * 100))%")
                                .font(.caption2)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Progress trend chart")
            .accessibilityValue(chartAccessibilityDescription(data: data))
        }
        .cardStyle()
    }

    private func chartAccessibilityDescription(data: [DashboardViewModel.ChartDataPointViewModel]) -> String {
        guard !data.isEmpty else { return Strings.Accessibility.chartNoData }
        let avgCompletion = data.map { $0.completionRate }.reduce(0, +) / Double(data.count)
        let firstRate = data.first?.completionRate ?? 0
        let lastRate = data.last?.completionRate ?? 0
        let trend = data.count > 1 && lastRate > firstRate ? "improving" : "declining"
        return Strings.Accessibility.chartDescription(avgCompletion: Int(avgCompletion * 100), trend: trend)
    }
    
    @ViewBuilder
    private func weeklyPatternsSection(patterns: DashboardViewModel.WeeklyPatternsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
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
    private func streakAnalysisSection(analysis: DashboardViewModel.StreakAnalysisViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Period Streaks")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Performance during selected period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(analysis.daysWithFullCompletion)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Perfect Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(analysis.longestStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Peak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", analysis.consistencyScore * 100))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.brand)
                    Text("Consistency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Trend indicator
            HStack {
                Image(systemName: analysis.streakTrend == "improving" ? "arrow.up.circle.fill" :
                      analysis.streakTrend == "declining" ? "arrow.down.circle.fill" : "minus.circle.fill")
                    .foregroundColor(analysis.streakTrend == "improving" ? .green :
                                   analysis.streakTrend == "declining" ? .red : .orange)
                
                Text("Period trend: \(analysis.streakTrend.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private func categoryBreakdownSection(categories: [DashboardViewModel.CategoryPerformanceViewModel]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Category Performance")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            ForEach(categories.prefix(5)) { category in
                Button {
                    navigationService.navigateToHabits(withCategoryId: category.id)
                } label: {
                    HStack(spacing: 12) {
                        // Category indicator
                        HStack(spacing: 6) {
                            if let emoji = category.emoji {
                                Text(emoji)
                                    .font(.title3)
                                    .accessibilityHidden(true) // Decorative emoji
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: category.color) ?? AppColors.brand)
                                    .frame(width: 16, height: 16)
                                    .accessibilityHidden(true) // Decorative color indicator
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.categoryName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                                Text("\(category.habitCount) habits")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Progress bar and percentage with modern gradient
                        HStack(spacing: 8) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(CardDesign.secondaryBackground)
                                    .frame(width: 60, height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: CircularProgressView.adaptiveProgressColors(for: category.completionRate),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60 * category.completionRate, height: 8)
                            }
                            .accessibilityHidden(true) // Progress bar is decorative, info conveyed via label

                            Text("\(Int((category.completionRate * 100).rounded()))%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .frame(minWidth: 44, alignment: .trailing)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
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
        }
        .cardStyle()
    }
    
    // MARK: - Habit Patterns Helpers
    
    @ViewBuilder
    private func thresholdRequirementsContent(requirements: [DashboardViewModel.ThresholdRequirement]) -> some View {
        VStack(spacing: 16) {
            // Header message
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.brand.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "scope")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.brand)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Building Your Profile")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text("Complete these to unlock insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Requirements list with progress bars
            VStack(spacing: 10) {
                ForEach(Array(requirements.enumerated()), id: \.offset) { _, requirement in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(requirement.isMet ? .green : .secondary)

                            Text(requirement.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)

                            Spacer()

                            Text(requirement.progressText)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(requirement.isMet ? .green : AppColors.brand)
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: requirement.isMet ?
                                                [.green.opacity(0.8), .green] :
                                                [AppColors.brand.opacity(0.7), AppColors.brand],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * requirement.progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func scheduleOptimizationContent(patterns: DashboardViewModel.WeeklyPatternsViewModel) -> some View {
        VStack(spacing: 16) {
            // Schedule insights based on data
            VStack(alignment: .leading, spacing: 12) {
                // Best performing day or consistent performance message
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
                            Text("Excellent every day")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)

                            Text("Consistent \(Int((patterns.averageWeeklyCompletion * 100).rounded()))% completion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if patterns.isConsistentPerformance {
                            Text("Consistent across all days")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)

                            Text("\(Int((patterns.averageWeeklyCompletion * 100).rounded()))% average completion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(patterns.bestDay) works best")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)

                            Text("\(Int((patterns.bestDayCompletionRate * 100).rounded()))% completion rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                // Smart optimization suggestion
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
                        Text(patterns.optimizationMessage)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        Text(patterns.isOptimizationMeaningful ? "Consider rescheduling some habits" : "No changes needed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            
            // Mini chart showing performance with gradient bars
            // Gradient reversed so result color (red/orange/green) shows at bottom for short bars
            Chart(patterns.dayOfWeekPerformance) { dayData in
                BarMark(
                    x: .value("Day", String(dayData.dayName.prefix(3))),
                    y: .value("Completion", dayData.completionRate)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: CircularProgressView.adaptiveProgressColors(for: dayData.completionRate).reversed(),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(CardDesign.innerCornerRadius / 2)
            }
            .frame(height: 100)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.2))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weekly performance chart")
            .accessibilityValue(
                patterns.isConsistentExcellence
                    ? "Excellent consistent performance at \(Int((patterns.averageWeeklyCompletion * 100).rounded()))% completion"
                    : patterns.isConsistentPerformance
                        ? "Consistent performance at \(Int((patterns.averageWeeklyCompletion * 100).rounded()))% average completion"
                        : "Best day is \(patterns.bestDay) at \(Int((patterns.bestDayCompletionRate * 100).rounded()))% completion"
            )
        }
    }
}

// swiftlint:enable type_body_length

#Preview {
    NavigationStack {
        DashboardView(vm: DashboardViewModel(logger: DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "ui")))
    }
}
