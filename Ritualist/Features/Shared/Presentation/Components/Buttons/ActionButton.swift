import SwiftUI
import RitualistCore

/// A standardized button component that provides consistent styling across the app
/// Supports iOS 26 glass buttons and various predefined styles
public struct ActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let style: ActionButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        style: ActionButtonStyle = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    public var body: some View {
        Group {
            if style == .glass26, #available(iOS 26.0, *) {
                Button(action: isDisabled || isLoading ? {} : action) {
                    buttonContent
                }
                .buttonStyle(IOS26GlassButtonStyle())
            } else {
                Button(action: isDisabled || isLoading ? {} : action) {
                    buttonContent
                }
                .buttonStyle(BounceStyle())
            }
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isLoading ? "Loading" : "")
    }

    private var accessibilityHint: String {
        if isLoading {
            return "Please wait"
        }
        if isDisabled {
            return "Button is currently disabled"
        }
        return "Double-tap to activate"
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: size.iconSpacing) {
            // Leading icon
            if let icon = icon, !isLoading {
                Image(systemName: icon)
                    .font(size.iconFont)
            }
            
            // Loading indicator
            if isLoading {
                ProgressView()
                    .scaleEffect(size.progressScale)
                    .progressViewStyle(CircularProgressViewStyle(
                        tint: style.foregroundColor(isDisabled: isDisabled)
                    ))
            }
            
            // Content
            VStack(spacing: 2) {
                Text(title)
                    .font(size.titleFont)
                    .fontWeight(size.fontWeight)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(size.subtitleFont)
                        .opacity(0.8)
                }
            }
            
            // Trailing icon for certain styles
            if style.hasTrailingChevron && icon == nil && !isLoading {
                Image(systemName: "chevron.right")
                    .font(size.chevronFont)
            }
        }
        .foregroundColor(style.foregroundColor(isDisabled: isDisabled))
        .padding(size.padding)
        .frame(maxWidth: size.maxWidth)
        .background(style.backgroundColor(isDisabled: isDisabled))
        .cornerRadius(size.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(
                    style.borderColor(isDisabled: isDisabled),
                    lineWidth: style.borderWidth
                )
        )
    }
    
    // MARK: - Private Properties
    
    private var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ". \(subtitle)"
        }
        if isDisabled {
            label += ". Disabled"
        }
        return label
    }
}

// MARK: - Action Button Style

public extension ActionButton {
    enum ActionButtonStyle: CaseIterable, Equatable {
        case primary
        case secondary
        case destructive
        case ghost
        case glass26
        
        func backgroundColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Color.gray.opacity(0.3)
            }
            
            switch self {
            case .primary:
                return AppColors.brand
            case .secondary:
                return Color.secondary.opacity(0.1)
            case .destructive:
                return Color.red
            case .ghost:
                return Color.clear
            case .glass26:
                if #available(iOS 26.0, *) {
                    return Color.clear // Glass effect handled by button style
                } else {
                    return AppColors.brand.opacity(0.1) // Fallback
                }
            }
        }
        
        func foregroundColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return .secondary
            }
            
            switch self {
            case .primary:
                return .white
            case .secondary:
                return .primary
            case .destructive:
                return .white
            case .ghost:
                return AppColors.brand
            case .glass26:
                return .primary
            }
        }
        
        func borderColor(isDisabled: Bool) -> Color {
            switch self {
            case .secondary, .ghost, .glass26:
                return isDisabled ? .secondary.opacity(0.3) : .secondary.opacity(0.2)
            default:
                return .clear
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .secondary, .ghost, .glass26:
                return 1
            default:
                return 0
            }
        }
        
        var hasTrailingChevron: Bool {
            switch self {
            case .ghost:
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - Button Size

public extension ActionButton {
    enum ButtonSize: CaseIterable {
        case small
        case medium
        case large
        
        var titleFont: Font {
            switch self {
            case .small: return .subheadline
            case .medium: return .body
            case .large: return .headline
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
            case .small: return .caption
            case .medium: return .body
            case .large: return .title3
            }
        }
        
        var chevronFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .small: return .medium
            case .medium: return .semibold
            case .large: return .bold
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            case .medium: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            case .large: return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return CornerRadius.small
            case .medium: return CornerRadius.medium
            case .large: return CornerRadius.large
            }
        }
        
        var maxWidth: CGFloat? {
            switch self {
            case .small: return nil
            case .medium: return nil
            case .large: return .infinity
            }
        }
        
        var iconSpacing: CGFloat {
            switch self {
            case .small: return Spacing.small
            case .medium: return Spacing.small
            case .large: return Spacing.medium
            }
        }
        
        var progressScale: CGFloat {
            switch self {
            case .small: return 0.7
            case .medium: return 0.8
            case .large: return 1.0
            }
        }
    }
}

// MARK: - iOS 26 Glass Button Style

@available(iOS 26.0, *)
private struct IOS26GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Convenience Initializers

public extension ActionButton {
    /// Primary action button (most common use)
    static func primary(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: icon,
            style: .primary,
            size: .medium,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    /// Secondary action button
    static func secondary(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: icon,
            style: .secondary,
            size: .medium,
            action: action
        )
    }
    
    /// Destructive action button (delete, remove, etc.)
    static func destructive(
        title: String,
        icon: String? = "trash",
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: icon,
            style: .destructive,
            size: .medium,
            action: action
        )
    }
    
    /// Ghost button for subtle actions
    static func ghost(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: icon,
            style: .ghost,
            size: .medium,
            action: action
        )
    }
    
    /// iOS 26 glass button (with fallback for older iOS)
    static func glass26(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: icon,
            style: .glass26,
            size: .medium,
            action: action
        )
    }
    
    /// Large call-to-action button
    static func cta(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            subtitle: subtitle,
            icon: icon,
            style: .primary,
            size: .large,
            isLoading: isLoading,
            action: action
        )
    }
}

#Preview("Action Buttons") {
    VStack(spacing: Spacing.medium) {
        ActionButton.primary(title: "Get Started", icon: "arrow.right") {}
        
        ActionButton.secondary(title: "Learn More") {}
        
        ActionButton.destructive(title: "Delete Habit") {}
        
        ActionButton.ghost(title: "View Details") {}
        
        ActionButton.glass26(title: "iOS 26 Glass", icon: "sparkles") {}
        
        ActionButton.cta(
            title: "Upgrade to Pro",
            subtitle: "Unlock all features",
            icon: "crown.fill",
            isLoading: false
        ) {}
        
        // Loading state example
        ActionButton.primary(title: "Creating...", isLoading: true) {}
        
        // Disabled state example
        ActionButton.primary(title: "Disabled", isDisabled: true) {}
    }
    .padding()
}