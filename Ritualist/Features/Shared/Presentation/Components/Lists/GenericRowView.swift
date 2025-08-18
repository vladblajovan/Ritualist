import SwiftUI
import RitualistCore

/// A generic row component that replaces all duplicate row implementations across the app
/// Supports various icon types, flexible content, and consistent styling
public struct GenericRowView: View {
    let icon: RowIcon?
    let title: String
    let subtitle: String?
    let badges: [RowBadge]
    let trailing: AnyView?
    let action: (() -> Void)?
    let isEnabled: Bool
    
    public init(
        icon: RowIcon? = nil,
        title: String,
        subtitle: String? = nil,
        badges: [RowBadge] = [],
        trailing: AnyView? = nil,
        action: (() -> Void)? = nil,
        isEnabled: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.badges = badges
        self.trailing = trailing
        self.action = action
        self.isEnabled = isEnabled
    }
    
    public var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: Spacing.medium) {
                // Icon Section
                if let icon = icon {
                    iconView(for: icon)
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    // Title
                    Text(title)
                        .font(.headline)
                        .foregroundColor(titleColor)
                        .strikethrough(!isEnabled && icon?.showStrikethrough == true)
                        .multilineTextAlignment(.leading)
                    
                    // Subtitle
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(subtitleColor)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Badges
                    if !badges.isEmpty {
                        HStack(spacing: Spacing.small) {
                            ForEach(badges.indices, id: \.self) { index in
                                badgeView(for: badges[index])
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Trailing Section
                if let trailing = trailing {
                    trailing
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isEnabled ? 1.0 : 0.7)
        .allowsHitTesting(action != nil)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(action != nil ? .isButton : [])
    }
    
    // MARK: - Icon View Builder
    
    @ViewBuilder
    private func iconView(for icon: RowIcon) -> some View {
        switch icon {
        case .emoji(let emoji):
            Text(emoji)
                .font(.title2)
                .frame(width: ComponentSize.iconMedium, height: ComponentSize.iconMedium)
                .opacity(isEnabled ? 1.0 : 0.5)
                
        case .systemImage(let name, let color):
            Image(systemName: name)
                .font(.title2)
                .foregroundColor(color ?? AppColors.brand)
                .frame(width: ComponentSize.iconMedium, height: ComponentSize.iconMedium)
                
        case .circleWithEmoji(let emoji, let backgroundColor):
            ZStack {
                Circle()
                    .fill((backgroundColor ?? AppColors.brand).opacity(0.1))
                    .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)
                Text(emoji)
                    .font(.title3)
            }
            
        case .circleWithIcon(let iconName, let color):
            ZStack {
                Circle()
                    .fill((color ?? AppColors.brand).opacity(0.1))
                    .frame(width: ComponentSize.iconMedium, height: ComponentSize.iconMedium)
                Image(systemName: iconName)
                    .font(.caption)
                    .foregroundColor(color ?? AppColors.brand)
            }
        }
    }
    
    // MARK: - Badge View Builder
    
    @ViewBuilder
    private func badgeView(for badge: RowBadge) -> some View {
        Text(badge.text)
            .font(.caption)
            .foregroundColor(badge.color)
    }
    
    // MARK: - Computed Properties
    
    private var titleColor: Color {
        if !isEnabled {
            return .secondary
        }
        
        if let icon = icon, case .systemImage = icon {
            return .primary
        }
        
        return .primary
    }
    
    private var subtitleColor: Color {
        .secondary
    }
    
    private var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ". \(subtitle)"
        }
        if !badges.isEmpty {
            let badgeTexts = badges.map { $0.text }.joined(separator: ", ")
            label += ". \(badgeTexts)"
        }
        if !isEnabled {
            label += ". Inactive"
        }
        return label
    }
}

// MARK: - Supporting Types

public extension GenericRowView {
    enum RowIcon: Equatable {
        case emoji(String)
        case systemImage(String, Color? = nil)
        case circleWithEmoji(String, backgroundColor: Color? = nil)
        case circleWithIcon(String, color: Color? = nil)
        
        var showStrikethrough: Bool {
            switch self {
            case .emoji: return true
            default: return false
            }
        }
    }
    
    struct RowBadge: Equatable {
        let text: String
        let color: Color
        
        public init(text: String, color: Color = .secondary) {
            self.text = text
            self.color = color
        }
        
        // Predefined badge types
        public static func active() -> RowBadge {
            RowBadge(text: "Active", color: .green)
        }
        
        public static func inactive() -> RowBadge {
            RowBadge(text: "Inactive", color: .orange)
        }
        
        public static func predefined() -> RowBadge {
            RowBadge(text: "Predefined", color: .secondary)
        }
        
        public static func custom(text: String, color: Color) -> RowBadge {
            RowBadge(text: text, color: color)
        }
    }
}

// MARK: - Convenience Initializers

public extension GenericRowView {
    /// For habit rows with emoji and status
    static func habitRow(
        habit: Habit,
        onTap: @escaping () -> Void
    ) -> GenericRowView {
        GenericRowView(
            icon: .circleWithEmoji(habit.emoji ?? "•", backgroundColor: Color(hex: habit.colorHex)),
            title: habit.name,
            subtitle: habit.isActive ? Strings.Status.active : Strings.Status.inactive,
            badges: [],
            trailing: AnyView(
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("View habit details")
            ),
            action: onTap,
            isEnabled: habit.isActive
        )
    }
    
    /// For habit rows with emoji, status, and schedule indicator
    static func habitRowWithSchedule(
        habit: Habit,
        scheduleStatus: HabitScheduleStatus,
        onTap: @escaping () -> Void
    ) -> GenericRowView {
        var badges: [RowBadge] = []
        
        // Add schedule badge
        badges.append(RowBadge(
            text: scheduleStatus.displayText,
            color: scheduleStatus.color
        ))
        
        // Add inactive badge if needed
        if !habit.isActive {
            badges.append(.inactive())
        }
        
        return GenericRowView(
            icon: .circleWithEmoji(habit.emoji ?? "•", backgroundColor: Color(hex: habit.colorHex)),
            title: habit.name,
            subtitle: scheduleStatus.isAvailable ? "Available for logging" : "Not scheduled today",
            badges: badges,
            trailing: AnyView(
                HStack(spacing: 8) {
                    HabitScheduleIndicator.compact(status: scheduleStatus)
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("View habit details")
                }
            ),
            action: onTap,
            isEnabled: habit.isActive && scheduleStatus.isAvailable
        )
    }
    
    /// For category rows with emoji and badges
    static func categoryRow(
        category: HabitCategory,
        onTap: (() -> Void)? = nil
    ) -> GenericRowView {
        var badges: [RowBadge] = []
        if !category.isActive {
            badges.append(.inactive())
        }
        
        return GenericRowView(
            icon: .emoji(category.emoji),
            title: category.displayName,
            subtitle: nil,
            badges: badges,
            trailing: nil,
            action: onTap,
            isEnabled: category.isActive
        )
    }
    
    /// For tip rows with system icons
    static func tipRow(
        tip: Tip,
        onTap: @escaping () -> Void
    ) -> GenericRowView {
        GenericRowView(
            icon: tip.icon != nil ? 
                .systemImage(tip.icon!, AppColors.brand) : 
                .circleWithIcon("lightbulb.fill", color: AppColors.brand),
            title: tip.title,
            subtitle: tip.description,
            badges: [],
            trailing: nil,
            action: onTap
        )
    }
    
    /// For settings rows with system icons
    static func settingsRow(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = AppColors.brand,
        onTap: @escaping () -> Void
    ) -> GenericRowView {
        GenericRowView(
            icon: .systemImage(icon, iconColor),
            title: title,
            subtitle: subtitle,
            badges: [],
            trailing: AnyView(
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            ),
            action: onTap
        )
    }
}

#Preview("Habit Row") {
    VStack(spacing: Spacing.medium) {
        GenericRowView.habitRow(
            habit: Habit(name: "Daily Exercise", emoji: "🏃‍♂️", isActive: true),
            onTap: {}
        )
        .padding()
        
        GenericRowView.habitRow(
            habit: Habit(name: "Meditation", emoji: "🧘‍♀️", isActive: false),
            onTap: {}
        )
        .padding()
    }
}

#Preview("Category Row") {
    VStack(spacing: Spacing.medium) {
        GenericRowView.categoryRow(
            category: HabitCategory(
                id: UUID().uuidString,
                name: "Health",
                displayName: "Health",
                emoji: "🏥",
                order: 0,
                isActive: true,
                isPredefined: true
            )
        )
        .padding()
        
        GenericRowView.categoryRow(
            category: HabitCategory(
                id: UUID().uuidString,
                name: "Custom Goal",
                displayName: "Custom Goal", 
                emoji: "🎯",
                order: 1,
                isActive: false,
                isPredefined: false
            )
        )
        .padding()
    }
}
