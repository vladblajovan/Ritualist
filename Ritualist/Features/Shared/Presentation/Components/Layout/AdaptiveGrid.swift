import SwiftUI
import RitualistCore

/// A container that automatically switches between single-column (iPhone) and multi-column (iPad) layouts
///
/// Use this to wrap groups of cards that should appear side-by-side on larger screens
/// but stack vertically on phones.
///
/// Example:
/// ```swift
/// AdaptiveGrid {
///     WeeklyPatternsCard()
///     StreakAnalysisCard()
/// }
/// ```
///
/// On iPhone: Cards stack vertically
/// On iPad: Cards appear side-by-side in a 2-column grid
public struct AdaptiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let spacing: CGFloat
    private let content: Content

    /// Creates an adaptive grid container
    /// - Parameters:
    ///   - spacing: Spacing between items (default: CardDesign.cardSpacing)
    ///   - content: The views to arrange adaptively
    public init(
        spacing: CGFloat = CardDesign.cardSpacing,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if horizontalSizeClass == .regular {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: spacing),
                    GridItem(.flexible(), spacing: spacing)
                ],
                spacing: spacing
            ) {
                content
            }
        } else {
            LazyVStack(spacing: spacing) {
                content
            }
        }
    }
}

/// A container that keeps content at a readable width on large screens
///
/// Use this for full-width content that shouldn't stretch too wide on iPad.
/// Centers the content and constrains max width.
///
/// Example:
/// ```swift
/// ReadableWidthContainer {
///     ProgressChartCard()
/// }
/// ```
public struct ReadableWidthContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let maxWidth: CGFloat
    private let content: Content

    /// Creates a readable width container
    /// - Parameters:
    ///   - maxWidth: Maximum width on regular size class (default: 700pt)
    ///   - content: The view to constrain
    public init(
        maxWidth: CGFloat = 700,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    public var body: some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity) // Centers the constrained content
        } else {
            content
        }
    }
}

/// A row that displays two views side-by-side with equal heights on iPad
///
/// On iPhone: Stacks vertically (no height equalization needed)
/// On iPad: Both views expand to match the taller one's height
///
/// Example:
/// ```swift
/// EqualHeightRow(spacing: 16) {
///     HabitPatternsCard()
/// } second: {
///     ProgressChartCard()
/// }
/// ```
/// A row that displays two views side-by-side on iPad
/// Cards should use `.frame(maxHeight: .infinity)` internally to expand and fill available space
public struct EqualHeightRow<First: View, Second: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let spacing: CGFloat
    private let first: First
    private let second: Second

    public init(
        spacing: CGFloat = CardDesign.cardSpacing,
        @ViewBuilder first: () -> First,
        @ViewBuilder second: () -> Second
    ) {
        self.spacing = spacing
        self.first = first()
        self.second = second()
    }

    public var body: some View {
        if horizontalSizeClass == .regular {
            // On iPad: Side-by-side with equal widths
            // Cards with .frame(maxHeight: .infinity) will stretch to match the taller one
            HStack(alignment: .top, spacing: spacing) {
                first
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                second
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .fixedSize(horizontal: false, vertical: true)
        } else {
            // iPhone: Stack vertically
            VStack(spacing: spacing) {
                first
                second
            }
        }
    }
}

// MARK: - Preview

#Preview("Adaptive Grid - Compact") {
    AdaptiveGrid {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.blue.opacity(0.3))
            .frame(height: 100)
            .overlay(Text("Card 1"))

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.green.opacity(0.3))
            .frame(height: 100)
            .overlay(Text("Card 2"))

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.orange.opacity(0.3))
            .frame(height: 100)
            .overlay(Text("Card 3"))
    }
    .padding()
}

#Preview("Readable Width Container") {
    ReadableWidthContainer {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.purple.opacity(0.3))
            .frame(height: 200)
            .overlay(Text("Chart Card"))
    }
    .padding()
}
