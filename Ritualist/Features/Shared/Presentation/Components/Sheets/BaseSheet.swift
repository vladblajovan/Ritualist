import SwiftUI
import RitualistCore

// MARK: - Sheet Sizing Configuration

/// Defines how a sheet should size itself responsively across different devices
public enum SheetSizing {
    case automatic                    // Content-driven height with measurement
    case fixed(CGFloat)              // Fixed height (use sparingly)
    case fraction(CGFloat)           // Percentage of screen height (0.0-1.0)
    case adaptive(min: CGFloat, ideal: CGFloat, max: CGFloat) // Adaptive with bounds
    case detents([PresentationDetent]) // Custom detent set
    case compact                     // ~40% for quick actions
    case medium                      // ~50% standard sheet
    case large                       // ~75% for complex content
    case fullScreen                  // 100% immersive experience
}

/// Configuration for scroll behavior within sheets
public struct ScrollConfiguration {
    let isEnabled: Bool
    let showsIndicators: Bool
    let dismissOnDrag: Bool
    let bounces: Bool
    let alwaysScrollable: Bool  // Force scrolling even with small content
    
    public init(
        isEnabled: Bool = true,
        showsIndicators: Bool = false,
        dismissOnDrag: Bool = true,
        bounces: Bool = true,
        alwaysScrollable: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.showsIndicators = showsIndicators
        self.dismissOnDrag = dismissOnDrag
        self.bounces = bounces
        self.alwaysScrollable = alwaysScrollable
    }
    
    /// Standard configuration for most sheets
    public static let standard = ScrollConfiguration()
    
    /// Minimal scrolling for simple content
    public static let minimal = ScrollConfiguration(
        showsIndicators: false,
        alwaysScrollable: false
    )
    
    /// Disabled scrolling for non-scrollable content
    public static let disabled = ScrollConfiguration(
        isEnabled: false,
        alwaysScrollable: false
    )
    
    /// Always scrollable for accessibility
    public static let accessible = ScrollConfiguration(
        showsIndicators: true,
        alwaysScrollable: true
    )
}

/// A base sheet component that provides consistent sheet presentation patterns across the app
/// Supports different sheet styles and standardizes navigation, toolbars, and loading states
/// Now includes smart sizing and responsive design for all device sizes
public struct BaseSheet<Content: View>: View {
    let title: String
    let subtitle: String?
    let style: SheetStyle
    let sizing: SheetSizing
    let scrollConfig: ScrollConfiguration
    let dismissButton: DismissButton?
    let primaryAction: SheetAction?
    let secondaryAction: SheetAction?
    let isLoading: Bool
    let minContentHeight: CGFloat?
    let respectsSafeArea: Bool
    let supportsDynamicType: Bool
    let onDismiss: () -> Void
    let content: () -> Content
    
    @Environment(\.dismiss) private var dismiss
    @State private var measuredContentHeight: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    
    public init(
        title: String,
        subtitle: String? = nil,
        style: SheetStyle = .navigation,
        sizing: SheetSizing = .automatic,
        scrollConfig: ScrollConfiguration = .standard,
        dismissButton: DismissButton? = DismissButton(title: "Done"),
        primaryAction: SheetAction? = nil,
        secondaryAction: SheetAction? = nil,
        isLoading: Bool = false,
        minContentHeight: CGFloat? = nil,
        respectsSafeArea: Bool = true,
        supportsDynamicType: Bool = true,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.sizing = sizing
        self.scrollConfig = scrollConfig
        self.dismissButton = dismissButton
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.isLoading = isLoading
        self.minContentHeight = minContentHeight
        self.respectsSafeArea = respectsSafeArea
        self.supportsDynamicType = supportsDynamicType
        self.onDismiss = onDismiss
        self.content = content
    }
    
    public var body: some View {
        Group {
            switch style {
            case .navigation:
                navigationSheet
            case .modal:
                modalSheet
            case .card:
                cardSheet
            case .fullScreen:
                fullScreenSheet
            }
        }
        .disabled(isLoading)
        .modifier(ResponsiveSizingModifier(
            sizing: sizing,
            measuredHeight: measuredContentHeight,
            screenHeight: screenHeight,
            minHeight: minContentHeight,
            respectsSafeArea: respectsSafeArea
        ))
        .onAppear {
            // Capture screen height for responsive calculations
            screenHeight = UIScreen.main.bounds.height
            // Announce sheet title to VoiceOver for focus management
            DispatchQueue.main.asyncAfter(deadline: .now() + AccessibilityConfig.voiceOverAnnouncementDelay) {
                UIAccessibility.post(notification: .screenChanged, argument: title)
            }
        }
    }
    
    // MARK: - Sheet Variations
    
    @ViewBuilder
    private var navigationSheet: some View {
        NavigationView {
            contentView
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
        }
    }
    
    @ViewBuilder
    private var modalSheet: some View {
        VStack(spacing: 0) {
            // Header
            modalHeader
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.top, Spacing.medium)
                .padding(.bottom, Spacing.small)
            
            Divider()
            
            // Content
            contentView
                .padding(.horizontal, Spacing.screenMargin)
        }
    }
    
    @ViewBuilder
    private var cardSheet: some View {
        VStack(spacing: Spacing.large) {
            // Header with icon/illustration
            cardHeader
            
            // Content
            contentView
            
            // Actions
            if hasActions {
                cardActions
            }
        }
        .padding(Spacing.screenMargin)
    }
    
    @ViewBuilder
    private var fullScreenSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header for full screen
                fullScreenHeader
                
                // Content
                contentView
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else {
            ResponsiveContentView(
                scrollConfig: scrollConfig,
                supportsDynamicType: supportsDynamicType,
                onHeightMeasured: { height in
                    measuredContentHeight = height
                },
                content: {
                    content()
                }
            )
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: Spacing.medium) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Headers
    
    @ViewBuilder
    private var modalHeader: some View {
        HStack {
            if let dismissButton = dismissButton {
                Button(dismissButton.title) {
                    handleDismiss()
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let primaryAction = primaryAction {
                Button(primaryAction.title) {
                    primaryAction.action()
                }
                .foregroundColor(primaryAction.style.color)
                .fontWeight(.semibold)
                .disabled(primaryAction.isDisabled)
            }
        }
    }
    
    @ViewBuilder
    private var cardHeader: some View {
        VStack(spacing: Spacing.medium) {
            // Large emoji or icon
            Text("📋") // Default icon, can be customized
                .font(.system(size: 60))
            
            VStack(spacing: Spacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    @ViewBuilder
    private var fullScreenHeader: some View {
        HStack {
            if dismissButton != nil {
                Button(action: handleDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if let primaryAction = primaryAction {
                Button(primaryAction.title) {
                    primaryAction.action()
                }
                .foregroundColor(primaryAction.style.color)
                .fontWeight(.semibold)
                .disabled(primaryAction.isDisabled)
            } else {
                // Invisible spacer to center title
                Button("") {}
                    .opacity(0)
                    .disabled(true)
            }
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.medium)
    }
    
    // MARK: - Actions
    
    @ViewBuilder
    private var cardActions: some View {
        VStack(spacing: Spacing.small) {
            if let primaryAction = primaryAction {
                ActionButton(
                    title: primaryAction.title,
                    style: primaryAction.style.actionButtonStyle,
                    size: .large,
                    isLoading: primaryAction.isLoading,
                    isDisabled: primaryAction.isDisabled,
                    action: primaryAction.action
                )
            }
            
            if let secondaryAction = secondaryAction {
                ActionButton(
                    title: secondaryAction.title,
                    style: secondaryAction.style.actionButtonStyle,
                    size: .medium,
                    isDisabled: secondaryAction.isDisabled,
                    action: secondaryAction.action
                )
            }
            
            if let dismissButton = dismissButton {
                ActionButton(
                    title: dismissButton.title,
                    style: .ghost,
                    size: .medium,
                    action: handleDismiss
                )
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Dismiss button
        if let dismissButton = dismissButton {
            ToolbarItem(placement: .topBarLeading) {
                Button(dismissButton.title) {
                    handleDismiss()
                }
            }
        }
        
        // Primary action
        if let primaryAction = primaryAction {
            ToolbarItem(placement: .topBarTrailing) {
                Button(primaryAction.title) {
                    primaryAction.action()
                }
                .fontWeight(.semibold)
                .foregroundColor(primaryAction.style.color)
                .disabled(primaryAction.isDisabled)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var hasActions: Bool {
        primaryAction != nil || secondaryAction != nil
    }
    
    // MARK: - Actions
    
    private func handleDismiss() {
        onDismiss()
        dismiss()
    }
}

// MARK: - Supporting Types

public struct DismissButtonPresets {
    public static let done = BaseSheet<AnyView>.DismissButton(title: "Done")
    public static let cancel = BaseSheet<AnyView>.DismissButton(title: "Cancel")
    public static let close = BaseSheet<AnyView>.DismissButton(title: "Close")
    public static let back = BaseSheet<AnyView>.DismissButton(title: "Back")
}

public extension BaseSheet {
    enum SheetStyle: CaseIterable {
        case navigation  // NavigationView with toolbar
        case modal       // Custom header with divider
        case card        // Card-like with centered content and bottom actions
        case fullScreen  // Full screen with custom navigation
    }

    struct DismissButton: Equatable {
        let title: String

        public init(title: String) {
            self.title = title
        }
    }

    enum SheetActionStyle: CaseIterable {
        case primary, secondary, destructive

        var color: Color {
            switch self {
            case .primary: return AppColors.brand
            case .secondary: return .primary
            case .destructive: return .red
            }
        }

        var actionButtonStyle: ActionButton.ActionButtonStyle {
            switch self {
            case .primary: return .primary
            case .secondary: return .secondary
            case .destructive: return .destructive
            }
        }
    }

    struct SheetAction: Equatable {
        let title: String
        let style: SheetActionStyle
        let isDisabled: Bool
        let isLoading: Bool
        let action: () -> Void

        public init(
            title: String,
            style: SheetActionStyle = .primary,
            isDisabled: Bool = false,
            isLoading: Bool = false,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.style = style
            self.isDisabled = isDisabled
            self.isLoading = isLoading
            self.action = action
        }

        public static func == (lhs: SheetAction, rhs: SheetAction) -> Bool {
            lhs.title == rhs.title &&
            lhs.style == rhs.style &&
            lhs.isDisabled == rhs.isDisabled &&
            lhs.isLoading == rhs.isLoading
        }
    }
}

// MARK: - Helper Components

/// Content wrapper that provides responsive scrolling and height measurement
private struct ResponsiveContentView<Content: View>: View {
    let scrollConfig: ScrollConfiguration
    let supportsDynamicType: Bool
    let onHeightMeasured: (CGFloat) -> Void
    let content: () -> Content
    
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        let shouldScroll = scrollConfig.isEnabled || scrollConfig.alwaysScrollable || DeviceCapabilities.shouldForceScrolling
        
        Group {
            if shouldScroll {
                ScrollView(.vertical, showsIndicators: scrollConfig.showsIndicators || DeviceCapabilities.hasAccessibilityDynamicType) {
                    LazyVStack {
                        content()
                            .background(heightMeasurementBackground)
                    }
                }
                .scrollBounceBasedOnSize()
            } else {
                content()
                    .background(heightMeasurementBackground)
            }
        }
        .dynamicTypeSize(supportsDynamicType ? .xSmall ... .accessibility5 : .large ... .large)
    }
    
    // MARK: - Height Measurement Background
    
    @ViewBuilder
    private var heightMeasurementBackground: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    contentHeight = geometry.size.height
                    onHeightMeasured(contentHeight)
                }
                .onChange(of: geometry.size.height) { _, newHeight in
                    contentHeight = newHeight
                    onHeightMeasured(contentHeight)
                }
        }
    }
}

/// ViewModifier that applies responsive sizing to sheets
private struct ResponsiveSizingModifier: ViewModifier {
    let sizing: SheetSizing
    let measuredHeight: CGFloat
    let screenHeight: CGFloat
    let minHeight: CGFloat?
    let respectsSafeArea: Bool
    
    func body(content: Content) -> some View {
        content
            .presentationDetents(detentsForSizing)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
    }
    
    private var detentsForSizing: Set<PresentationDetent> {
        // Use intelligent device-aware recommendations for most cases
        if case .fixed(let height) = sizing {
            return Set([.height(height)])
        } else if case .detents(let customDetents) = sizing {
            return Set(customDetents)
        } else if case .fullScreen = sizing {
            return Set([.large])
        } else {
            // For all other cases, use smart device-aware recommendations
            return DeviceCapabilities.recommendedDetents(for: sizing, contentHeight: measuredHeight)
        }
    }
}

// MARK: - Device Capability Detection

/// Helper for detecting device capabilities and screen characteristics
public struct DeviceCapabilities {
    
    // MARK: - Screen Size Detection
    
    /// iPhone SE (1st, 2nd, 3rd gen) or similar small screens
    static var isSmallScreen: Bool {
        let bounds = UIScreen.main.bounds
        return bounds.width <= 375 && bounds.height <= 667 // iPhone SE 3rd gen and smaller
    }
    
    /// iPhone mini series (iPhone 12 mini, 13 mini)
    static var isMiniScreen: Bool {
        let bounds = UIScreen.main.bounds
        return bounds.width == 375 && bounds.height == 812 // iPhone mini dimensions
    }
    
    /// Compact height (landscape orientation or small screens)
    static var isCompactHeight: Bool {
        UIScreen.main.bounds.height < 700
    }
    
    /// Large screen (Pro Max series, Plus series)
    static var isLargeScreen: Bool {
        let bounds = UIScreen.main.bounds
        return bounds.width >= 414 && bounds.height >= 896
    }
    
    /// iPad detection
    static var isTablet: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // MARK: - Hardware Features
    
    /// Home indicator present (iPhone X and later)
    static var hasHomeIndicator: Bool {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom > 0
        }
        return false
    }
    
    /// Dynamic Island or Notch present
    static var hasNotchOrDynamicIsland: Bool {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top > 20
        }
        return false
    }
    
    // MARK: - Accessibility
    
    /// User has increased Dynamic Type beyond standard range
    static var hasAccessibilityDynamicType: Bool {
        let contentSize = UIApplication.shared.preferredContentSizeCategory
        return contentSize >= .accessibilityMedium
    }
    
    /// Reduced motion enabled
    static var hasReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    // MARK: - Screen Metrics
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var safeAreaTop: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
    }
    
    static var safeAreaBottom: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom
        }
        return 0
    }
    
    // MARK: - Smart Recommendations
    
    /// Recommended minimum height for sheets on this device
    static var recommendedMinHeight: CGFloat {
        if isTablet {
            return 400
        } else if isSmallScreen {
            return 300
        } else if isMiniScreen {
            return 320
        } else {
            return 350
        }
    }
    
    /// Maximum recommended height fraction for sheets
    static var recommendedMaxHeightFraction: CGFloat {
        if isCompactHeight {
            return 0.8  // Less space in landscape
        } else if isSmallScreen {
            return 0.85 // More aggressive on small screens
        } else if isTablet {
            return 0.7  // iPad should show more background
        } else {
            return 0.9  // Standard phones
        }
    }
    
    /// Whether scrolling should be forced for accessibility
    static var shouldForceScrolling: Bool {
        hasAccessibilityDynamicType || isSmallScreen
    }
    
    /// Get optimized detents for a given sizing mode
    static func recommendedDetents(for sizing: SheetSizing, contentHeight: CGFloat = 0) -> Set<PresentationDetent> {
        let screenHeight = self.screenHeight
        let maxFraction = recommendedMaxHeightFraction
        let minHeight = recommendedMinHeight
        
        switch sizing {
        case .automatic:
            if contentHeight > 0 {
                let idealHeight = max(contentHeight + 100, minHeight)
                let maxHeight = screenHeight * maxFraction
                let clampedHeight = min(idealHeight, maxHeight)
                return Set([.height(clampedHeight), .large])
            } else {
                return Set([.medium, .large])
            }
            
        case .compact:
            if isSmallScreen {
                return Set([.height(minHeight), .medium])
            } else {
                return Set([.fraction(0.4), .medium])
            }
            
        case .medium:
            if isTablet {
                return Set([.fraction(0.4), .fraction(0.6), .large])
            } else {
                return Set([.medium, .large])
            }
            
        case .large:
            if isCompactHeight {
                return Set([.fraction(0.7), .large])
            } else {
                return Set([.fraction(0.75), .large])
            }
            
        case .adaptive(let min, let ideal, let max):
            let adjustedMin = Swift.max(min, minHeight)
            let adjustedMax = Swift.min(max, screenHeight * maxFraction)
            let adjustedIdeal = Swift.max(adjustedMin, Swift.min(ideal, adjustedMax))
            return Set([.height(adjustedMin), .height(adjustedIdeal), .height(adjustedMax)])
            
        default:
            // For other cases, fall back to the standard implementation
            return Set([.medium, .large])
        }
    }
}

// MARK: - ScrollView Extensions

private extension View {
    func scrollBounceBasedOnSize() -> some View {
        if #available(iOS 16.4, *) {
            return self.scrollBounceBehavior(.basedOnSize)
        } else {
            return self
        }
    }
}

// MARK: - Public Extensions

public extension View {
    /// Apply responsive sheet sizing to any view
    func responsiveSheetSizing(
        _ sizing: SheetSizing = .automatic,
        minHeight: CGFloat? = nil,
        respectsSafeArea: Bool = true
    ) -> some View {
        self.modifier(ResponsiveSheetSizingModifier(
            sizing: sizing,
            minHeight: minHeight,
            respectsSafeArea: respectsSafeArea
        ))
    }
}

/// Public ViewModifier for applying responsive sizing to any existing sheet
public struct ResponsiveSheetSizingModifier: ViewModifier {
    let sizing: SheetSizing
    let minHeight: CGFloat?
    let respectsSafeArea: Bool
    
    @State private var measuredHeight: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    
    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            measuredHeight = geometry.size.height
                            screenHeight = UIScreen.main.bounds.height
                        }
                        .onChange(of: geometry.size.height) { _, newHeight in
                            measuredHeight = newHeight
                        }
                }
            )
            .presentationDetents(detentsForSizing)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
    }
    
    private var detentsForSizing: Set<PresentationDetent> {
        // Use intelligent device-aware recommendations for most cases
        if case .fixed(let height) = sizing {
            return Set([.height(height)])
        } else if case .detents(let customDetents) = sizing {
            return Set(customDetents)
        } else if case .fullScreen = sizing {
            return Set([.large])
        } else {
            // For all other cases, use smart device-aware recommendations
            return DeviceCapabilities.recommendedDetents(for: sizing, contentHeight: measuredHeight)
        }
    }
}

#Preview("Base Sheets") {
    VStack(spacing: Spacing.medium) {
        // Automatic sizing sheet
        BaseSheet(
            title: "Smart Settings", 
            subtitle: "Automatically sized sheet",
            sizing: .automatic,
            scrollConfig: .standard
        ) {
            VStack(spacing: Spacing.medium) {
                Text("This sheet automatically adjusts its height based on content")
                Toggle("Enable notifications", isOn: .constant(true))
                Toggle("Dark mode", isOn: .constant(false))
                Toggle("Haptic feedback", isOn: .constant(true))
                Text("Content adapts to screen size and Dynamic Type settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        
        // Compact sheet example
        BaseSheet(
            title: "Quick Action", 
            sizing: .compact,
            scrollConfig: .minimal
        ) {
            VStack(spacing: Spacing.small) {
                Text("Compact sheet for quick actions")
                ActionButton.primary(title: "Confirm") {}
            }
            .padding()
        }
        
        // Adaptive sheet example
        BaseSheet(
            title: "Adaptive Content",
            sizing: .adaptive(min: 300, ideal: 500, max: 700),
            scrollConfig: .accessible
        ) {
            VStack(spacing: Spacing.medium) {
                ForEach(1...10, id: \.self) { index in
                    Text("Content item \(index)")
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    .padding()
}
