//
//  WidgetGradientBackground.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 20.08.2025.
//

import SwiftUI
import RitualistCore

/// Beautiful gradient background for widgets - matches main app design
/// Fills entire widget area without any white gaps
struct WidgetGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: gradientStops),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var gradientStops: [Gradient.Stop] {
        if colorScheme == .dark {
            return [
                .init(color: .ritualistDarkNavy, location: 0.0),
                .init(color: .ritualistDeepNavy, location: 0.5),
                .init(color: .ritualistDarkNavy, location: 1.0)
            ]
        } else {
            return [
                .init(color: .ritualistCyan, location: 0.0),
                .init(color: .ritualistBlue.opacity(0.8), location: 0.5),
                .init(color: .ritualistCyan, location: 1.0)
            ]
        }
    }
}

#Preview("Widget Gradient Background") {
    WidgetGradientBackground()
        .frame(width: 338, height: 354)
}