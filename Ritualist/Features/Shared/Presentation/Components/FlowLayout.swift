//
//  FlowLayout.swift
//  Ritualist
//
//  A custom Layout for flowing content that wraps to multiple lines.
//

import SwiftUI

/// Custom Layout implementation for flowing content that wraps to multiple rows.
/// Uses iOS 16+ Layout protocol for precise control over item positioning.
/// Implements caching to avoid redundant size calculations on repeated layout passes.
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    // MARK: - Cache

    /// Cache stores pre-computed subview sizes to avoid recalculating on every layout pass.
    /// SwiftUI may call sizeThatFits and placeSubviews multiple times per frame.
    struct CacheData {
        var subviewSizes: [CGSize]
    }

    func makeCache(subviews: Subviews) -> CacheData {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return CacheData(subviewSizes: sizes)
    }

    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        cache.subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
    }

    // MARK: - Layout

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        // Use proposed width, fallback to reasonable default (rare in practice)
        let containerWidth = proposal.width ?? 300
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for index in subviews.indices {
            let subviewSize = cache.subviewSizes[index]

            // Check if adding this item would exceed container width.
            // currentRowWidth includes spacing from previous items (inter-item spacing).
            // We only add spacing AFTER placing an item, so the check is correct:
            // "Does current accumulated width + new item fit within bounds?"
            if currentRowWidth + subviewSize.width > containerWidth && currentRowWidth > 0 {
                totalHeight += rowHeight + spacing
                currentRowWidth = 0
                rowHeight = 0
            }

            // Add item width plus trailing spacing (becomes inter-item spacing for next item)
            currentRowWidth += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }

        // Add height of last row
        totalHeight += rowHeight

        // Return calculated height, or 0 for empty layouts.
        // Note: Returning 0 is safe - SwiftUI handles zero-height views gracefully.
        // Previous implementation used max(_, 1) but that caused 1pt artifacts.
        return CGSize(width: containerWidth, height: totalHeight)
    }

    // Note: `proposal` parameter is required by the Layout protocol but unused here.
    // We use `bounds` for placement constraints and cached sizes for subview dimensions.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let subviewSize = cache.subviewSizes[index]

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
