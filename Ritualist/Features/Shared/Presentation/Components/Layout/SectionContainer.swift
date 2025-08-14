import SwiftUI
import RitualistCore

/// A container component that provides consistent section styling across the app
/// Supports section titles, subtitles, and optional header actions
public struct SectionContainer<Content: View>: View {
    let title: String?
    let subtitle: String?
    let headerAction: HeaderAction?
    let spacing: CGFloat
    let showDivider: Bool
    let content: () -> Content
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        headerAction: HeaderAction? = nil,
        spacing: CGFloat = Spacing.medium,
        showDivider: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.headerAction = headerAction
        self.spacing = spacing
        self.showDivider = showDivider
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Header Section
            if hasHeader {
                header
                    .accessibilityAddTraits(.isHeader)
            }
            
            // Divider
            if showDivider && hasHeader {
                Divider()
                    .padding(.horizontal, -Spacing.medium)
            }
            
            // Content Section
            content()
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Private Views
    
    private var hasHeader: Bool {
        title != nil || subtitle != nil || headerAction != nil
    }
    
    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let headerAction = headerAction {
                Button(action: headerAction.action) {
                    HStack(spacing: Spacing.xxsmall) {
                        Text(headerAction.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if headerAction.showChevron {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(AppColors.brand)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(headerAction.accessibilityLabel ?? headerAction.title)
                .accessibilityAddTraits(.isButton)
            }
        }
    }
}

// MARK: - Supporting Types

public extension SectionContainer {
    struct HeaderAction {
        let title: String
        let showChevron: Bool
        let accessibilityLabel: String?
        let action: () -> Void
        
        public init(
            title: String,
            showChevron: Bool = true,
            accessibilityLabel: String? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.showChevron = showChevron
            self.accessibilityLabel = accessibilityLabel
            self.action = action
        }
        
        // Predefined actions
        public static func viewAll(action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(title: "View All", action: action)
        }
        
        public static func seeMore(action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(title: "See More", action: action)
        }
        
        public static func edit(action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(title: "Edit", showChevron: false, action: action)
        }
        
        public static func add(action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(title: "Add", showChevron: false, action: action)
        }
        
        public static func manage(action: @escaping () -> Void) -> HeaderAction {
            HeaderAction(title: "Manage", action: action)
        }
    }
}


// MARK: - Specialized Containers

/// Grid section for cards or stats
public struct GridSection<Content: View>: View {
    let title: String?
    let subtitle: String?
    let columns: [GridItem]
    let spacing: CGFloat
    let content: () -> Content
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        columns: [GridItem],
        spacing: CGFloat = Spacing.medium,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        SectionContainer(title: title, subtitle: subtitle, spacing: spacing) {
            LazyVGrid(columns: columns, spacing: Spacing.medium) {
                content()
            }
        }
    }
}

/// Horizontal scroll section
public struct HorizontalScrollSection<Content: View>: View {
    let title: String?
    let action: SectionContainer<Content>.HeaderAction?
    let showsIndicators: Bool
    let content: () -> Content
    
    public init(
        title: String? = nil,
        action: SectionContainer<Content>.HeaderAction? = nil,
        showsIndicators: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.action = action
        self.showsIndicators = showsIndicators
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let action = action {
                        Button(action: action.action) {
                            HStack(spacing: Spacing.xxsmall) {
                                Text(action.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if action.showChevron {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(AppColors.brand)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: showsIndicators) {
                LazyHStack(spacing: Spacing.medium) {
                    content()
                }
                .padding(.horizontal, Spacing.screenMargin)
            }
            .clipped()
        }
    }
}

#Preview("Section Container Examples") {
    ScrollView {
        VStack(spacing: Spacing.large) {
            // Simple titled section
            SectionContainer(title: "Recent Activity") {
                VStack(spacing: Spacing.small) {
                    Text("Activity item 1")
                    Text("Activity item 2")
                    Text("Activity item 3")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Section with description
            SectionContainer(
                title: "Your Progress",
                subtitle: "Track your daily habits and streaks"
            ) {
                VStack(spacing: Spacing.small) {
                    HStack {
                        Text("Exercise")
                        Spacer()
                        Text("7 day streak")
                    }
                    HStack {
                        Text("Reading")
                        Spacer()
                        Text("3 day streak")
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Grid section
            GridSection(
                title: "Statistics",
                columns: [GridItem(.flexible()), GridItem(.flexible())]
            ) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.3))
                        .frame(height: 80)
                }
            }
        }
        .padding()
    }
}
