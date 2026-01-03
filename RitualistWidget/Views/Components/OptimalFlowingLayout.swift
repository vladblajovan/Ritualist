//
//  OptimalFlowingLayout.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 20.08.2025.
//

import SwiftUI

// MARK: - LazyVGrid Solution (Most Optimal)

/// Optimal flowing layout using LazyVGrid with adaptive columns
/// Perfect for widgets: predictable, performant, and native SwiftUI behavior
struct AdaptiveFlowingLayout<Content: View>: View {
    let spacing: CGFloat
    let itemWidth: CGFloat
    let content: () -> Content
    
    init(itemWidth: CGFloat = 50, spacing: CGFloat = 6, @ViewBuilder content: @escaping () -> Content) {
        self.itemWidth = itemWidth
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: itemWidth, maximum: itemWidth), spacing: spacing)
            ],
            spacing: spacing
        ) {
            content()
        }
    }
}

// MARK: - Custom Layout Solution (iOS 16+)

/// Custom Layout implementation for precise control
/// Use when LazyVGrid doesn't provide enough flexibility
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 6) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 338
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // Check if we need to wrap to next row
            if currentRowWidth + subviewSize.width > containerWidth && currentRowWidth > 0 {
                totalHeight += rowHeight + spacing
                currentRowWidth = 0
                rowHeight = 0
            }
            
            currentRowWidth += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
        
        // Add height of last row
        totalHeight += rowHeight
        
        return CGSize(width: containerWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // Check if we need to wrap to next row
            if currentX + subviewSize.width > bounds.maxX && currentX > bounds.minX {
                currentY += rowHeight + spacing
                currentX = bounds.minX
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            
            currentX += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
    }
}

// MARK: - Calculated Chunking Solution

/// Simple chunking approach with VStack + HStack
/// Most predictable for widget constraints
struct ChunkedFlowingLayout<Content: View>: View {
    let items: [AnyView]
    let itemWidth: CGFloat
    let containerWidth: CGFloat
    let spacing: CGFloat
    
    init<Data: RandomAccessCollection, ID: Hashable>(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        itemWidth: CGFloat = 50,
        containerWidth: CGFloat = 338,
        spacing: CGFloat = 6,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.itemWidth = itemWidth
        self.containerWidth = containerWidth
        self.spacing = spacing
        
        // Calculate items per row based on container width
        let availableWidth = containerWidth - (spacing * 2) // Account for padding
        let itemsPerRow = max(1, Int(availableWidth / (itemWidth + spacing)))
        
        // Convert data to AnyView chunks
        let chunks = data.chunked(into: itemsPerRow)
        self.items = chunks.map { chunk in
            AnyView(
                HStack(spacing: spacing) {
                    ForEach(Array(chunk.enumerated()), id: \.offset) { _, item in
                        content(item)
                            .frame(width: itemWidth)
                    }
                    Spacer(minLength: 0)
                }
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(items.indices, id: \.self) { index in
                items[index]
            }
        }
    }
}

// MARK: - Helper Extensions

extension RandomAccessCollection {
    func chunked(into size: Int) -> [[Element]] {
        var result: [[Element]] = []
        var currentIndex = startIndex
        
        while currentIndex < endIndex {
            let nextIndex = index(currentIndex, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[currentIndex..<nextIndex]))
            currentIndex = nextIndex
        }
        
        return result
    }
}

// MARK: - Usage Examples
/*
 Usage Example for LazyVGrid (Recommended):
 
 AdaptiveFlowingLayout(itemWidth: 50, spacing: 6) {
     ForEach(habits, id: \.habit.id) { habitInfo in
         WidgetHabitChip(
             habitDisplayInfo: habitInfo,
             isViewingToday: true,
             selectedDate: Date(),
             widgetSize: .large
         )
         .frame(width: 50, height: 50)
     }
 }
 */

// MARK: - Performance Comparison

/*
 PERFORMANCE ANALYSIS FOR WIDGET CONTEXT:
 
 1. LazyVGrid with Adaptive Columns: ⭐⭐⭐⭐⭐
    - Native SwiftUI optimization
    - Predictable layout behavior
    - Minimal CPU overhead
    - Perfect for fixed-size items
    - Widget-friendly (no complex calculations)
 
 2. Custom Layout (iOS 16+): ⭐⭐⭐⭐
    - Maximum flexibility
    - Precise control over positioning
    - More CPU overhead during layout
    - Requires iOS 16+ (your target is iOS 17+)
 
 3. Chunked VStack+HStack: ⭐⭐⭐⭐⭐
    - Ultra-predictable for widgets
    - Pre-calculated layout
    - Zero runtime layout complexity
    - Works perfectly with fixed constraints
 
 4. GeometryReader + Mirror (Current): ⭐⭐
    - Complex runtime reflection
    - Performance overhead from Mirror
    - Unpredictable in widget context
    - Maintenance complexity
 
 RECOMMENDATION: Use LazyVGrid for most cases, Chunked approach for maximum predictability
 */
