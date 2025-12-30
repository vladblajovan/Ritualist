//
//  CrownProBadge.swift
//  Ritualist
//
//  Reusable crown PRO badge component for premium features.
//

import SwiftUI
import RitualistCore

/// Reusable crown PRO badge for indicating premium features
///
/// Usage:
/// ```swift
/// CrownProBadge()                    // With crown icon (default)
/// CrownProBadge(showCrownIcon: false) // Text only
/// ```
struct CrownProBadge: View {
    var showCrownIcon: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if showCrownIcon {
                Image(systemName: "crown.fill")
                    .font(.caption2)
            }
            Text("PRO")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(GradientTokens.premiumCrown)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CrownProBadge()

        // In context
        HStack {
            Text("Export")
            Spacer()
            CrownProBadge()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    .padding()
}
