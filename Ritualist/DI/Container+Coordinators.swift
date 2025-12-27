//
//  Container+Coordinators.swift
//  Ritualist
//
//  DI registration for app coordinators
//

import Foundation
import FactoryKit
import RitualistCore

extension Container {

    // MARK: - Deep Link Handler

    var deepLinkHandler: Factory<DeepLinkHandler> {
        self {
            MainActor.assumeIsolated {
                DeepLinkHandler(
                    urlValidationService: self.urlValidationService(),
                    navigationService: self.navigationService(),
                    logger: self.debugLogger()
                )
            }
        }
        .singleton
    }

    // MARK: - Timezone Change Handler

    var timezoneChangeHandler: Factory<TimezoneChangeHandler> {
        self {
            MainActor.assumeIsolated {
                TimezoneChangeHandler(
                    timezoneService: self.timezoneService(),
                    dailyNotificationScheduler: self.dailyNotificationScheduler(),
                    toastService: self.toastService(),
                    logger: self.debugLogger()
                )
            }
        }
        .singleton
    }

    // MARK: - iCloud Sync Coordinator

    var iCloudSyncCoordinator: Factory<ICloudSyncCoordinator> {
        self {
            MainActor.assumeIsolated {
                ICloudSyncCoordinator(
                    syncWithiCloud: self.syncWithiCloud(),
                    updateLastSyncDate: self.updateLastSyncDate(),
                    checkiCloudStatus: self.checkiCloudStatus(),
                    deduplicateData: self.deduplicateData(),
                    cloudKitCleanupService: self.cloudKitCleanupService(),
                    userDefaults: self.userDefaultsService(),
                    profileCache: self.profileCache(),
                    logger: self.debugLogger(),
                    userActionTracker: self.userActionTracker()
                )
            }
        }
        .singleton
    }

    // MARK: - App Lifecycle Coordinator

    @MainActor
    func appLifecycleCoordinator(appStartTime: Date) -> AppLifecycleCoordinator {
        AppLifecycleCoordinator(
            notificationService: notificationService(),
            dailyNotificationScheduler: dailyNotificationScheduler(),
            restoreGeofenceMonitoring: restoreGeofenceMonitoring(),
            seedPredefinedCategories: seedPredefinedCategories(),
            iCloudSyncCoordinator: iCloudSyncCoordinator(),
            timezoneChangeHandler: timezoneChangeHandler(),
            logger: debugLogger(),
            userActionTracker: userActionTracker(),
            appStartTime: appStartTime
        )
    }
}
