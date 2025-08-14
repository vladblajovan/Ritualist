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
                    if let chartData = vm.progressChartData {
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
                ForEach(DashboardViewModel.TimePeriod.allCases, id: \.self) { period in
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.brand.opacity(0.3), AppColors.brand.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
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
                    Text("Perfect Day Patterns")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Which days achieve full completion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Best/Worst days for system-wide completion
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strongest Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(patterns.bestDay)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Challenge Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(patterns.worstDay)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            // Bar chart for days of week
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
            .frame(height: 120)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
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
                
                Text("Streak Analysis")
                    .font(.headline)
                    .foregroundColor(.primary)
                
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
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(analysis.longestStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Best")
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
                
                Text("Trend: \(analysis.streakTrend.capitalized)")
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
}

// swiftlint:enable type_body_length

#Preview {
    NavigationStack {
        DashboardView(vm: DashboardViewModel())
    }
}
