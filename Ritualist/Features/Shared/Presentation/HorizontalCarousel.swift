import SwiftUI
import RitualistCore

public struct HorizontalCarousel<T: Identifiable, Content: View>: View {
    let items: [T]
    let selectedItem: T?
    let onItemTap: (T) async -> Void
    let onItemLongPress: ((T) -> Void)?
    let content: (T, Bool) -> Content
    let showPageIndicator: Bool
    let itemSpacing: CGFloat
    let horizontalPadding: CGFloat
    let pageIndicatorThreshold: Int
    
    public init(
        items: [T],
        selectedItem: T?,
        onItemTap: @escaping (T) async -> Void,
        onItemLongPress: ((T) -> Void)? = nil,
        showPageIndicator: Bool = true,
        itemSpacing: CGFloat = Spacing.medium,
        horizontalPadding: CGFloat = 16,
        pageIndicatorThreshold: Int = 3,
        @ViewBuilder content: @escaping (T, Bool) -> Content
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.onItemTap = onItemTap
        self.onItemLongPress = onItemLongPress
        self.content = content
        self.showPageIndicator = showPageIndicator
        self.itemSpacing = itemSpacing
        self.horizontalPadding = horizontalPadding
        self.pageIndicatorThreshold = pageIndicatorThreshold
    }
    
    public var body: some View {
        VStack(spacing: Spacing.small) {
            // Horizontal scroll view with items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: itemSpacing) {
                    ForEach(items) { item in
                        content(item, selectedItem?.id == item.id)
                            .onTapGesture {
                                Task { await onItemTap(item) }
                            }
                            .onLongPressGesture(minimumDuration: 0.5) {
                                onItemLongPress?(item)
                            }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
            .mask(
                // Fade out edges when content overflows
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 0.95),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Page indicator
            if showPageIndicator && items.count > pageIndicatorThreshold {
                HStack(spacing: Spacing.xxsmall) {
                    ForEach(0..<min(items.count, 5), id: \.self) { index in
                        Circle()
                            .fill(selectedItem?.id == items[index].id ? AppColors.brand : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                    
                    if items.count > 5 {
                        Text("...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
        .padding(.vertical, 12)
    }
}
