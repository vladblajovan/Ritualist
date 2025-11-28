//
//  AppLaunchView.swift
//  Ritualist
//
//  Created by Claude on 27.11.2025.
//
//  Branded launch screen shown while detecting iCloud data.
//  Provides a seamless transition from the iOS launch screen.
//

import SwiftUI
import RitualistCore

/// Branded launch screen with app icon and loading spinner.
/// Shown during initial iCloud data detection on fresh install.
struct AppLaunchView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon from bundle
            if let uiImage = Bundle.main.appIcon {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .animatedGlow(glowSize: 220)
            }

            // App name
            Text("Ritualist")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            // Loading spinner
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.brand)
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    AppLaunchView()
}
