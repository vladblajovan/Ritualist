//
//  FlowLayout.swift
//  Ritualist
//
//  A custom Layout for flowing content that wraps to multiple lines.
//

import SwiftUI

/// Custom Layout implementation for flowing content that wraps to multiple rows
/// Uses iOS 16+ Layout protocol for precise control over item positioning
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 300
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
