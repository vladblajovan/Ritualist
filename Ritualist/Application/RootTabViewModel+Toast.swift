//
//  RootTabViewModel+Toast.swift
//  Ritualist
//

import Foundation
import RitualistCore

// MARK: - Toast Display Model

extension RootTabViewModel {
    /// View-friendly toast representation that doesn't expose internal ToastService types
    public struct ToastDisplayItem: Identifiable {
        public let id: UUID
        public let message: String
        public let icon: String
        public let style: ToastStyle
        public let isPersistent: Bool
    }
}

// MARK: - Toast Helpers

extension RootTabViewModel {
    // MARK: - Toast Management

    /// Check if any toast is currently being displayed
    public var isToastActive: Bool {
        toastService.hasActiveToasts
    }

    /// Active toasts for display (view-friendly representation)
    public var toastItems: [ToastDisplayItem] {
        toastService.toasts.map { toast in
            ToastDisplayItem(
                id: toast.id,
                message: toast.type.message,
                icon: toast.type.icon,
                style: toast.type.style,
                isPersistent: toast.persistent
            )
        }
    }

    /// Dismiss a specific toast by ID
    public func dismissToast(_ id: UUID) {
        toastService.dismiss(id)
    }

    /// Show toast for successful iCloud sync
    public func showSyncedToast() {
        toastService.info(Strings.ICloudSync.syncedFromCloud, icon: "icloud.fill")
    }

    /// Show toast when sync is still in progress
    public func showStillSyncingToast() {
        toastService.info(Strings.ICloudSync.stillSyncing, icon: "icloud.and.arrow.down")
    }

    /// Show persistent toast while syncing data from iCloud for returning users
    /// This toast stays visible until manually dismissed
    /// Only shows once per session to prevent duplicate appearances
    ///
    /// iCloud sync is free for all users, so this always shows for returning users.
    public func showSyncingDataToast() {
        guard !hasShownSyncingToast else { return }
        hasShownSyncingToast = true
        toastService.infoPersistent(Strings.ICloudSync.syncingData, icon: "icloud.and.arrow.down")
    }

    /// Dismiss the syncing data toast (call when sync completes or returning user welcome shows)
    public func dismissSyncingDataToast() {
        toastService.dismiss(message: Strings.ICloudSync.syncingData)
    }
}
