import SwiftUI
import RitualistCore

/// A visual indicator showing the schedule status of a habit
public struct HabitScheduleIndicator: View {
    let status: HabitScheduleStatus
    let size: IndicatorSize
    let style: IndicatorStyle
    
    public enum IndicatorSize {
        case small
        case medium
        case large
        case xlarge

        var iconFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .footnote
            case .xlarge: return .system(size: 14)
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .footnote
            case .xlarge: return .subheadline
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            case .xlarge: return 10
            }
        }
    }
    
    public enum IndicatorStyle {
        case iconOnly
        case textOnly
        case iconWithText
        case badge
        
        var showsIcon: Bool {
            switch self {
            case .iconOnly, .iconWithText, .badge:
                return true
            case .textOnly:
                return false
            }
        }
        
        var showsText: Bool {
            switch self {
            case .textOnly, .iconWithText:
                return true
            case .iconOnly, .badge:
                return false
            }
        }
    }
    
    public init(
        status: HabitScheduleStatus,
        size: IndicatorSize = .medium,
        style: IndicatorStyle = .iconWithText
    ) {
        self.status = status
        self.size = size
        self.style = style
    }
    
    public var body: some View {
        Group {
            switch style {
            case .badge:
                badgeView
            default:
                standardView
            }
        }
        .accessibilityLabel(status.accessibilityLabel)
    }
    
    private var standardView: some View {
        HStack(spacing: 4) {
            if style.showsIcon {
                Image(systemName: status.iconName)
                    .font(size.iconFont)
                    .foregroundColor(status.color)
            }
            
            if style.showsText {
                Text(status.displayText)
                    .font(size.fontSize)
                    .foregroundColor(status.color)
            }
        }
        .opacity(status.isAvailable ? 1.0 : 0.7)
    }
    
    private var badgeView: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(size.iconFont)
                .foregroundColor(status.isAvailable ? .white : status.color)
            
            if style.showsText {
                Text(status.displayText)
                    .font(size.fontSize)
                    .foregroundColor(status.isAvailable ? .white : status.color)
            }
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding / 2)
        .background(
            RoundedRectangle(cornerRadius: size.padding)
                .fill(status.isAvailable ? status.color : status.color.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: size.padding)
                .stroke(status.color.opacity(0.3), lineWidth: status.isAvailable ? 0 : 1)
        )
    }
}

// MARK: - Convenience Initializers

public extension HabitScheduleIndicator {
    /// Creates a small icon-only indicator for compact spaces
    static func compact(status: HabitScheduleStatus) -> HabitScheduleIndicator {
        HabitScheduleIndicator(status: status, size: .small, style: .iconOnly)
    }
    
    /// Creates a badge-style indicator for prominent display
    static func badge(status: HabitScheduleStatus) -> HabitScheduleIndicator {
        HabitScheduleIndicator(status: status, size: .medium, style: .badge)
    }
    
    /// Creates a full indicator with icon and text
    static func full(status: HabitScheduleStatus) -> HabitScheduleIndicator {
        HabitScheduleIndicator(status: status, size: .medium, style: .iconWithText)
    }
}

#Preview("Schedule Indicators") {
    VStack(spacing: 16) {
        // Different status types
        Group {
            HabitScheduleIndicator.full(status: .scheduledToday)
            HabitScheduleIndicator.full(status: .notScheduledToday)
            HabitScheduleIndicator.full(status: .alwaysScheduled)
        }
        
        Divider()
        
        // Different styles
        HStack(spacing: 16) {
            HabitScheduleIndicator.compact(status: .scheduledToday)
            HabitScheduleIndicator.badge(status: .scheduledToday)
            HabitScheduleIndicator.full(status: .scheduledToday)
        }
        
        // Different sizes
        HStack(spacing: 16) {
            HabitScheduleIndicator(status: .notScheduledToday, size: .small, style: .iconWithText)
            HabitScheduleIndicator(status: .notScheduledToday, size: .medium, style: .iconWithText)
            HabitScheduleIndicator(status: .notScheduledToday, size: .large, style: .iconWithText)
        }
    }
    .padding()
}