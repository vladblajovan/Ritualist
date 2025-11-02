import SwiftUI
import RitualistCore

/// An enhanced stats card component with trend indicators and flexible layouts
/// Replaces the dashboard-specific StatsCard with more features and customization
public struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let color: Color
    let trend: TrendIndicator?
    let layout: CardLayout
    let size: CardSize
    let action: (() -> Void)?
    
    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        color: Color = AppColors.brand,
        trend: TrendIndicator? = nil,
        layout: CardLayout = .vertical,
        size: CardSize = .medium,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
        self.layout = layout
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    contentView
                }
                .buttonStyle(CardButtonStyle())
            } else {
                contentView
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        Group {
            switch layout {
            case .vertical:
                verticalLayout
            case .horizontal:
                horizontalLayout
            case .compact:
                compactLayout
            }
        }
        .frame(maxWidth: .infinity, alignment: layoutAlignment)
        .modifier(CardStyle())
    }
    
    // MARK: - Layout Variations
    
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: size.verticalSpacing) {
            // Header row with icon and trend
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.iconFont)
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let trend = trend {
                    trendView(trend)
                }
            }
            
            // Value
            Text(value)
                .font(size.valueFont)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(size.titleFont)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(size.subtitleFont)
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
    }
    
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: size.horizontalSpacing) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(size.iconFont)
                    .foregroundColor(color)
                    .frame(width: size.iconSize, height: size.iconSize)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(value)
                        .font(size.valueFont)
                        .foregroundColor(.primary)
                    
                    if let trend = trend {
                        trendView(trend)
                    }
                }
                
                Text(title)
                    .font(size.titleFont)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(size.subtitleFont)
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var compactLayout: some View {
        HStack(spacing: size.horizontalSpacing) {
            // Icon and value in a compact row
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.iconFont)
                        .foregroundColor(color)
                }
                
                Text(value)
                    .font(size.valueFont)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Title and trend
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(size.titleFont)
                        .foregroundColor(.secondary)
                    
                    if let trend = trend {
                        trendView(trend)
                    }
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(size.subtitleFont)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Trend View
    
    @ViewBuilder
    private func trendView(_ trend: TrendIndicator) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.iconName)
                .font(.caption)
            
            if let percentage = trend.percentage {
                Text(trend.formattedPercentage)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trend.color.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Computed Properties
    
    private var layoutAlignment: Alignment {
        switch layout {
        case .vertical: return .leading
        case .horizontal: return .leading
        case .compact: return .center
        }
    }
}

// MARK: - Supporting Types

public extension StatCard {
    enum TrendIndicator: Equatable {
        case up(Double?)
        case down(Double?)
        case neutral
        case custom(String, Double?, Color)
        
        var iconName: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            case .custom(let icon, _, _): return icon
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            case .custom(_, _, let color): return color
            }
        }
        
        var percentage: Double? {
            switch self {
            case .up(let value): return value
            case .down(let value): return value
            case .neutral: return nil
            case .custom(_, let value, _): return value
            }
        }
        
        var formattedPercentage: String {
            guard let percentage = percentage else { return "" }
            return String(format: "%.1f%%", abs(percentage))
        }
    }
    
    enum CardLayout: CaseIterable {
        case vertical    // Icon top, value center, title bottom
        case horizontal  // Icon left, content center-left
        case compact     // Icon+value left, title+trend right
    }
    
    enum CardSize: CaseIterable {
        case small, medium, large
        
        var valueFont: Font {
            switch self {
            case .small: return .system(size: 20, weight: .bold, design: .rounded)
            case .medium: return .system(size: 28, weight: .bold, design: .rounded)
            case .large: return .system(size: 36, weight: .bold, design: .rounded)
            }
        }
        
        var titleFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .body
            }
        }
        
        var subtitleFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var iconFont: Font {
            switch self {
            case .small: return .body
            case .medium: return .title2
            case .large: return .title
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 40
            }
        }
        
        var verticalSpacing: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
        
        var horizontalSpacing: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
    }
}

// MARK: - Button Styles

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(CardStyle())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}


// MARK: - Convenience Initializers

public extension StatCard {
    /// Simple stat card (most common use case)
    static func simple(
        title: String,
        value: String,
        icon: String,
        color: Color = AppColors.brand
    ) -> StatCard {
        StatCard(
            title: title,
            value: value,
            icon: icon,
            color: color
        )
    }
    
    /// Stat card with trend
    static func withTrend(
        title: String,
        value: String,
        icon: String,
        color: Color = AppColors.brand,
        trend: TrendIndicator
    ) -> StatCard {
        StatCard(
            title: title,
            value: value,
            icon: icon,
            color: color,
            trend: trend
        )
    }
    
    /// Compact stat card for lists or smaller spaces
    static func compact(
        title: String,
        value: String,
        icon: String? = nil,
        color: Color = AppColors.brand,
        trend: TrendIndicator? = nil
    ) -> StatCard {
        StatCard(
            title: title,
            value: value,
            icon: icon,
            color: color,
            trend: trend,
            layout: .compact,
            size: .small
        )
    }
    
    /// Large feature stat card
    static func featured(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color = AppColors.brand,
        trend: TrendIndicator? = nil,
        action: (() -> Void)? = nil
    ) -> StatCard {
        StatCard(
            title: title,
            value: value,
            subtitle: subtitle,
            icon: icon,
            color: color,
            trend: trend,
            layout: .vertical,
            size: .large,
            action: action
        )
    }
    
    /// Horizontal layout stat card
    static func horizontal(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = AppColors.brand,
        action: (() -> Void)? = nil
    ) -> StatCard {
        StatCard(
            title: title,
            value: value,
            subtitle: subtitle,
            icon: icon,
            color: color,
            layout: .horizontal,
            size: .medium,
            action: action
        )
    }
}

#Preview("Stat Cards") {
    ScrollView {
        VStack(spacing: Spacing.large) {
            // Simple cards grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard.simple(
                    title: "Total Habits",
                    value: "12",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard.simple(
                    title: "Completed Today",
                    value: "8",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            // Cards with trends
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard.withTrend(
                    title: "Weekly Progress",
                    value: "85%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    trend: .up(12.5)
                )
                
                StatCard.withTrend(
                    title: "Streak Count",
                    value: "7",
                    icon: "flame.fill",
                    color: .orange,
                    trend: .down(3.2)
                )
            }
            
            // Large featured card
            StatCard.featured(
                title: "Current Streak",
                value: "21",
                subtitle: "days in a row",
                icon: "flame.fill",
                color: .orange,
                trend: .up(nil)
            ) {
                print("Featured card tapped")
            }
            
            // Compact cards
            VStack(spacing: Spacing.small) {
                StatCard.compact(
                    title: "Exercise",
                    value: "45m",
                    icon: "figure.run",
                    color: .blue,
                    trend: .up(8.1)
                )
                
                StatCard.compact(
                    title: "Reading",
                    value: "2 books",
                    icon: "book.fill",
                    color: .purple
                )
                
                StatCard.compact(
                    title: "Meditation",
                    value: "15m",
                    icon: "leaf.fill",
                    color: .green,
                    trend: .neutral
                )
            }
            
            // Horizontal layout
            VStack(spacing: Spacing.small) {
                StatCard.horizontal(
                    title: "Daily Goal Progress",
                    value: "8/10",
                    subtitle: "habits completed",
                    icon: "target",
                    color: .blue
                )
                
                StatCard.horizontal(
                    title: "Weekly Consistency",
                    value: "92%",
                    icon: "calendar.badge.checkmark",
                    color: .green
                ) {
                    print("Weekly consistency tapped")
                }
            }
        }
        .padding()
    }
}