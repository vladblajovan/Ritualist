import SwiftUI
import RitualistCore

/// Unified permissions section for Notifications and Location
struct PermissionsSectionView: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section("Permissions") {
            // Notifications Permission Row
            PermissionRow(
                icon: vm.hasNotificationPermission ? "bell.fill" : "bell.slash.fill",
                iconColor: vm.hasNotificationPermission ? .green : .orange,
                title: Strings.Settings.notificationPermission,
                subtitle: vm.hasNotificationPermission ?
                    Strings.Settings.notificationsEnabled :
                    Strings.Settings.notificationsDisabled,
                isRequesting: vm.isRequestingNotifications,
                isGranted: vm.hasNotificationPermission,
                requestAction: {
                    Task { await vm.requestNotifications() }
                },
                settingsAction: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                },
                requestAccessibilityLabel: "Request notification permission",
                requestAccessibilityHint: "Tap to enable notifications",
                settingsAccessibilityLabel: "Open notification settings",
                settingsAccessibilityHint: "Opens iOS Settings app"
            )

            // Location Permission Row
            PermissionRow(
                icon: vm.locationAuthStatus.canMonitorGeofences ? "location.fill" : "location.slash.fill",
                iconColor: vm.locationAuthStatus.canMonitorGeofences ? .green : .orange,
                title: "Location Permission",
                subtitle: vm.locationAuthStatus.displayText,
                isRequesting: vm.isRequestingLocationPermission,
                isGranted: vm.locationAuthStatus.canMonitorGeofences,
                requestAction: {
                    Task { await vm.requestLocationPermission() }
                },
                settingsAction: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                },
                requestAccessibilityLabel: "Request location permission",
                requestAccessibilityHint: "Tap to enable location services",
                settingsAccessibilityLabel: "Open location settings",
                settingsAccessibilityHint: "Opens iOS Settings app"
            )
        }
    }
}

/// Standardized permission row component with consistent icon size and layout
private struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isRequesting: Bool
    let isGranted: Bool
    let requestAction: () -> Void
    let settingsAction: () -> Void
    let requestAccessibilityLabel: String
    let requestAccessibilityHint: String
    let settingsAccessibilityLabel: String
    let settingsAccessibilityHint: String

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Status icon (standardized to IconSize.large)
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)
                .frame(width: IconSize.large)

            // Title and description
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Action button
            if isRequesting {
                ProgressView()
                    .scaleEffect(ScaleFactors.smallMedium)
            } else if !isGranted {
                Button(action: requestAction) {
                    Image(systemName: icon == "bell.slash.fill" ? "bell.badge" : icon)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(requestAccessibilityLabel)
                .accessibilityHint(requestAccessibilityHint)
            } else {
                Button(action: settingsAction) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(settingsAccessibilityLabel)
                .accessibilityHint(settingsAccessibilityHint)
            }
        }
        .padding(.vertical, Spacing.small)
    }
}
