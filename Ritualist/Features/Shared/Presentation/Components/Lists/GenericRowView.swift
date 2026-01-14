import SwiftUI
import FactoryKit
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
        .opacity(isEnabled ? 1.0 : 0.6)
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
                    .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
                Text(emoji)
                    .font(.title2)
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
            label += ". \(Strings.Components.inactive)"
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
            RowBadge(text: Strings.Components.active, color: .green)
        }

        public static func inactive() -> RowBadge {
            RowBadge(text: Strings.Components.inactive, color: .orange)
        }

        public static func predefined() -> RowBadge {
            RowBadge(text: Strings.Components.predefined, color: .secondary)
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
                    .accessibilityLabel(Strings.Components.viewHabitDetails)
            ),
            action: onTap,
            isEnabled: habit.isActive
        )
    }
    
    /// For habit rows with emoji, status, and schedule indicator with split hit zones
    static func habitRowWithSchedule(
        habit: Habit,
        scheduleStatus: HabitScheduleStatus,
        onTap: @escaping () -> Void
    ) -> some View {
        HabitRowWithSplitZones(
            habit: habit,
            scheduleStatus: scheduleStatus,
            onTap: onTap
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

// MARK: - Habit Row with Split Hit Zones

/// Habit row with split hit zones: main content taps to view details, icon area shows info sheet
private struct HabitRowWithSplitZones: View {
    let habit: Habit
    let scheduleStatus: HabitScheduleStatus
    let onTap: () -> Void

    @Injected(\.subscriptionService) private var subscriptionService
    @State private var showingIconInfoSheet = false
    @State private var isPremiumUser = false

    private var isEnabled: Bool {
        habit.isActive && scheduleStatus.isAvailable
    }

    var body: some View {
        HStack(spacing: 0) {
            // LEFT ZONE: Main content - tappable for habit details
            Button(action: onTap) {
                HStack(spacing: Spacing.medium) {
                    // Habit emoji icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: habit.colorHex).opacity(0.1))
                            .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
                        Text(habit.emoji ?? "•")
                            .font(.title2)
                    }

                    // Content Section
                    VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                        // Title
                        Text(habit.name)
                            .font(.headline)
                            .foregroundColor(isEnabled ? .primary : .secondary)
                            .strikethrough(!habit.isActive)
                            .multilineTextAlignment(.leading)

                        // Badges
                        HStack(spacing: Spacing.small) {
                            if !habit.isActive {
                                // Only show inactive badge for inactive habits
                                Text(Strings.Components.inactive)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                // Show schedule badge for active habits
                                Text(scheduleStatus.displayText)
                                    .font(.caption)
                                    .foregroundColor(scheduleStatus.color)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // RIGHT ZONE: Icon area - tappable for info sheet
            Button {
                showingIconInfoSheet = true
            } label: {
                HStack(spacing: 8) {
                    // Time-based reminders indicator (only for premium users with reminders)
                    if isPremiumUser && !habit.reminders.isEmpty {
                        Image(systemName: "bell.fill")
                            .font(.body)
                            .foregroundColor(.orange)
                            .accessibilityLabel(Strings.Components.timeRemindersEnabled)
                    }

                    // Location indicator (only for premium users with location enabled)
                    if isPremiumUser && habit.locationConfiguration?.isEnabled == true {
                        Image(systemName: "location.fill")
                            .font(.body)
                            .foregroundColor(.purple)
                            .accessibilityLabel(Strings.Components.locationRemindersEnabled)
                    }

                    // Schedule indicator - use .medium size to match Today card
                    HabitScheduleIndicator(status: scheduleStatus, size: .medium, style: .iconOnly)
                }
                .padding(.leading, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .opacity(isEnabled ? 1.0 : 0.7)
        .sheet(isPresented: $showingIconInfoSheet) {
            HabitIconInfoSheet()
        }
        .task {
            isPremiumUser = await subscriptionService.isPremiumUser()
        }
    }
}

// MARK: - Habit Icon Info Sheet

private struct HabitIconInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HabitIconInfoRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: Strings.Components.timeRemindersTitle,
                        description: Strings.Components.timeRemindersDesc
                    )

                    HabitIconInfoRow(
                        icon: "location.fill",
                        iconColor: .purple,
                        title: Strings.Components.locationRemindersTitle,
                        description: Strings.Components.locationRemindersDesc
                    )

                    HabitIconInfoRow(
                        icon: "infinity.circle.fill",
                        iconColor: .blue,
                        title: Strings.Components.alwaysAvailableTitle,
                        description: Strings.Components.alwaysAvailableDesc
                    )

                    HabitIconInfoRow(
                        icon: "calendar.circle.fill",
                        iconColor: .green,
                        title: Strings.Components.scheduledTodayTitle,
                        description: Strings.Components.scheduledTodayDesc
                    )

                    HabitIconInfoRow(
                        icon: "calendar.circle.fill",
                        iconColor: .green,
                        title: Strings.Components.notScheduledTodayTitle,
                        description: Strings.Components.notScheduledTodayDesc,
                        opacity: 0.7
                    )
                } header: {
                    Text(Strings.Components.habitIcons)
                } footer: {
                    Text(Strings.Components.habitIconsDescription)
                }
            }
            .navigationTitle(Strings.Components.habitIndicators)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Button.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HabitIconInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    var opacity: Double = 1.0

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)
                .opacity(opacity)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
