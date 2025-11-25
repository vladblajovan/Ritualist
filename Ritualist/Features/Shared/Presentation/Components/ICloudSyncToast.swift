//
//  ICloudSyncToast.swift
//  Ritualist
//
//  Created by Claude on 25.11.2025.
//

import SwiftUI
import RitualistCore

/// A toast notification that appears when iCloud syncs data from another device
/// Auto-dismisses after a short duration
struct ICloudSyncToast: View {
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "icloud.fill")
                .font(.body)
                .foregroundStyle(.white)

            Text(Strings.ICloudSync.syncedFromCloud)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(
            Capsule()
                .fill(Color.blue.gradient)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .task {
            // Animate in
            withAnimation {
                isVisible = true
            }

            // Auto-dismiss after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                isVisible = false
            }

            // Call dismiss after animation completes
            try? await Task.sleep(for: .milliseconds(500))
            onDismiss()
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    /// Posted when iCloud syncs data from another device
    /// Used to trigger the sync toast in RootTabView
    static let iCloudDidSyncRemoteChanges = Notification.Name("iCloudDidSyncRemoteChanges")
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        VStack {
            ICloudSyncToast(onDismiss: {})
                .padding(.top, 50)

            Spacer()
        }
    }
}
