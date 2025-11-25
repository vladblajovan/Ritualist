//
//  ICloudSyncToast.swift
//  Ritualist
//
//  iCloud sync notification using the reusable ToastView component
//

import SwiftUI
import RitualistCore

/// A toast notification that appears when iCloud syncs data from another device
/// Uses the reusable ToastView component
struct ICloudSyncToast: View {
    let onDismiss: () -> Void

    var body: some View {
        ToastView(
            message: Strings.ICloudSync.syncedFromCloud,
            icon: "icloud.fill",
            style: .info,
            onDismiss: onDismiss
        )
    }
}

// Note: Notification.Name.iCloudDidSyncRemoteChanges is defined in RitualistCore/Constants/AppConstants.swift

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
