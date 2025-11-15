import SwiftUI
import Charts
import RitualistCore

// swiftlint:disable type_body_length
public struct DashboardView: View {
    var vm: DashboardViewModel
    
    public init(vm: DashboardViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Time Period Selector
                timePeriodSelector
                
                // Main Stats Cards
                if vm.isLoading {
                    loadingView
                } else if let stats = vm.completionStats {
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
            .padding(.horizontal, Spacing.screenMargin)
        }
        .refreshable {
            await vm.refresh()
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await vm.loadData()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var timePeriodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button(action: { vm.selectedTimePeriod = period }) {
                        Text(period.displayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(vm.selectedTimePeriod == period ? .white : .primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(vm.selectedTimePeriod == period ? AppColors.brand : Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
        }
        .padding(.leading, -20)
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
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
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
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private func weeklyPatternsSection(patterns: DashboardViewModel.WeeklyPatternsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedule Optimization")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Optimize your habit scheduling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if patterns.isDataSufficient {
                // Show optimization insights when data is sufficient
                scheduleOptimizationContent(patterns: patterns)
            } else {
                // Show threshold requirements when data is insufficient
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
                    Text("\(analysis.currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("In Period")
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
                HStack(spacing: 12) {
                    // Category indicator
                    HStack(spacing: 6) {
                        if let emoji = category.emoji {
                            Text(emoji)
                                .font(.title3)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: category.color) ?? AppColors.brand)
                                .frame(width: 16, height: 16)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.categoryName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            Text("\(category.habitCount) habits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Progress bar and percentage
                    HStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: category.color) ?? AppColors.brand)
                                .frame(width: 60 * category.completionRate, height: 8)
                        }
                        
                        Text("\(Int(category.completionRate * 100))%")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Schedule Optimization Helpers
    
    @ViewBuilder
    private func thresholdRequirementsContent(requirements: [DashboardViewModel.ThresholdRequirement]) -> some View {
        VStack(spacing: 16) {
            // Header message
            VStack(spacing: 8) {
                Text("🎯")
                    .font(.system(size: 32))
                    .opacity(0.6)
                
                VStack(spacing: 4) {
                    Text("Building Your Profile")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Complete these requirements to unlock personalized scheduling insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Requirements list
            VStack(spacing: 12) {
                ForEach(Array(requirements.enumerated()), id: \.offset) { index, requirement in
                    HStack(spacing: 12) {
                        // Status icon
                        Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(requirement.isMet ? .green : .secondary)
                        
                        // Content
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(requirement.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(requirement.progressText)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(requirement.isMet ? .green : .secondary)
                            }
                            
                            Text(requirement.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func scheduleOptimizationContent(patterns: DashboardViewModel.WeeklyPatternsViewModel) -> some View {
        VStack(spacing: 16) {
            // Schedule insights based on data
            VStack(alignment: .leading, spacing: 12) {
                Text("Schedule Insights")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Best performing day
                HStack {
                    Text("🌟")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(patterns.bestDay) works best")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        let bestPerformance = patterns.dayOfWeekPerformance.first { $0.dayName == patterns.bestDay }
                        Text("\(Int((bestPerformance?.completionRate ?? 0) * 100))% completion rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Optimization suggestion
                HStack {
                    Text("⚡")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Try moving habits to \(patterns.bestDay)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Your highest success day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Mini chart showing performance
            Chart(patterns.dayOfWeekPerformance) { dayData in
                BarMark(
                    x: .value("Day", String(dayData.dayName.prefix(3))),
                    y: .value("Completion", dayData.completionRate)
                )
                .foregroundStyle(
                    dayData.dayName == patterns.bestDay ? .green :
                    dayData.dayName == patterns.worstDay ? .orange : .blue
                )
            }
            .frame(height: 80)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue * 100))%")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
    }
}

// swiftlint:enable type_body_length

#Preview {
    NavigationStack {
        DashboardView(vm: DashboardViewModel(logger: DebugLogger(subsystem: "com.ritualist.app", category: "ui")))
    }
}
