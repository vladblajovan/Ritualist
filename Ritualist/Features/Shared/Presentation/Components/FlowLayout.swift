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
        let containerWidth = proposal.width ?? 300
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for (index, _) in subviews.enumerated() {
            let subviewSize = cache.subviewSizes[index]

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

        // Ensure minimum height of 1 to avoid zero-height layout issues
        return CGSize(width: containerWidth, height: max(totalHeight, 1))
    }

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
