//
//  DebugMenuiCloudSection.swift
//  Ritualist
//

import SwiftUI
import RitualistCore

#if DEBUG
struct DebugMenuiCloudSection: View {
    @Bindable var vm: SettingsViewModel
    @State private var showingResetDiagnosticsConfirmation = false

    var body: some View {
        Section("iCloud Sync Diagnostics") {
            cloudKitConfigInfo
            pushNotificationInfo
            storeChangesInfo

            Button {
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await vm.forceCloudStatusCheck()
                }
            } label: {
                HStack {
                    Image(systemName: vm.isCheckingCloudStatus ? "hourglass" : "arrow.triangle.2.circlepath.icloud")
                        .foregroundColor(.blue)

                    Text(vm.isCheckingCloudStatus ? "Checking..." : "Force iCloud Status Check")

                    Spacer()
                }
            }
            .disabled(vm.isCheckingCloudStatus)

            Button(role: .destructive) {
                showingResetDiagnosticsConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.orange)

                    Text("Reset Sync Diagnostics")

                    Spacer()
                }
            }
            .alert("Reset Sync Diagnostics?", isPresented: $showingResetDiagnosticsConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    ICloudSyncDiagnostics.shared.reset()
                }
            } message: {
                Text("This will clear all recorded sync events and counters.")
            }

            Text("Sync flow: Push Received → Store Changes. If 'Registered' is No, check Push Notifications capability. If pushes come but no store changes, check CloudKit Stats schema deployment.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var cloudKitConfigInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CloudKit Configuration")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Container:")
                    Spacer()
                    Text(iCloudConstants.containerIdentifier)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Environment:")
                    Spacer()
                    #if DEBUG
                    Text("Development")
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    #else
                    Text("Production")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    #endif
                }

                HStack {
                    Text("iCloud Status:")
                    Spacer()
                    Text(vm.iCloudStatus.displayMessage)
                        .fontWeight(.medium)
                        .foregroundColor(vm.iCloudStatus == .available ? .green : .red)
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private var pushNotificationInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Push Notifications")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Registered:")
                    Spacer()
                    Text(ICloudSyncDiagnostics.shared.isRegisteredForRemoteNotifications ? "Yes" : "No")
                        .fontWeight(.medium)
                        .foregroundColor(ICloudSyncDiagnostics.shared.isRegisteredForRemoteNotifications ? .green : .red)
                }

                HStack {
                    Text("Push Received:")
                    Spacer()
                    Text("\(ICloudSyncDiagnostics.shared.pushNotificationCount)")
                        .fontWeight(.medium)
                        .foregroundColor(ICloudSyncDiagnostics.shared.pushNotificationCount > 0 ? .green : .secondary)
                }

                if let lastPush = ICloudSyncDiagnostics.shared.lastPushNotificationDate {
                    HStack {
                        Text("Last Push:")
                        Spacer()
                        Text(lastPush, format: .relative(presentation: .named))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private var storeChangesInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Store Changes")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Remote Changes:")
                    Spacer()
                    Text("\(ICloudSyncDiagnostics.shared.remoteChangeCount)")
                        .fontWeight(.medium)
                        .foregroundColor(ICloudSyncDiagnostics.shared.remoteChangeCount > 0 ? .green : .secondary)
                }

                if let lastChange = ICloudSyncDiagnostics.shared.lastRemoteChangeDate {
                    HStack {
                        Text("Last Sync:")
                        Spacer()
                        Text(lastChange, format: .relative(presentation: .named))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }

                HStack {
                    Text("Dedup Runs:")
                    Spacer()
                    Text("\(ICloudSyncDiagnostics.shared.deduplicationRunCount)")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Total Duplicates Removed:")
                    Spacer()
                    Text("\(ICloudSyncDiagnostics.shared.totalDuplicatesRemoved)")
                        .fontWeight(.medium)
                        .foregroundColor(ICloudSyncDiagnostics.shared.totalDuplicatesRemoved > 0 ? .orange : .secondary)
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}
#endif
