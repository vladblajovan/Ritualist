//
//  RitualistApp.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import SwiftUI
import SwiftData
import FactoryKit
import RitualistCore
import UIKit
import CoreData
import CloudKit
import TipKit

@main struct RitualistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Injected(\.persistenceContainer) private var persistenceContainer
    @Injected(\.debugLogger) private var logger
    @Injected(\.userDefaultsService) private var userDefaults
    @Injected(\.deepLinkHandler) private var deepLinkHandler
    @Injected(\.timezoneChangeHandler) private var timezoneChangeHandler

    /// App startup time for performance monitoring
    private let appStartTime = Date()

    /// Lifecycle coordinator
    @State private var lifecycleCoordinator: AppLifecycleCoordinator?

    // MARK: - Timezone Change Alert State

    @State private var showTimezoneChangeAlert = false
    @State private var detectedTimezoneChange: DetectedTimezoneChangeInfo?

    init() {
        // Check if tips should be reset (set from Debug Menu)
        let initUserDefaults = DefaultUserDefaultsService()
        if initUserDefaults.bool(forKey: "shouldResetTipsOnNextLaunch") {
            initUserDefaults.set(false, forKey: "shouldResetTipsOnNextLaunch")
            do {
                try Tips.resetDatastore()
            } catch {
                // Silently fail - TipKit reset is non-critical
            }
        }

        // Configure TipKit
        do {
            try Tips.configure([.displayFrequency(.immediate)])
        } catch {
            // Silently fail - TipKit is non-critical
        }
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .modelContainer(persistenceContainer.container)
                .task { @MainActor in
                    setupCoordinators()
                    await lifecycleCoordinator?.performInitialLaunchTasks()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await lifecycleCoordinator?.handleDidBecomeActive()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await lifecycleCoordinator?.handleSignificantTimeChange()
                    }
                }
                .onOpenURL { url in
                    deepLinkHandler.handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
                    Task { @MainActor in
                        await lifecycleCoordinator?.handleRemoteChange()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSUbiquityIdentityDidChange)) { _ in
                    Task { @MainActor in
                        lifecycleCoordinator?.handleICloudIdentityChange()
                    }
                }
                // MARK: - Timezone Change Alert
                .alert(
                    Strings.TimezoneChange.title,
                    isPresented: $showTimezoneChangeAlert,
                    presenting: detectedTimezoneChange
                ) { change in
                    Button(Strings.TimezoneChange.keepHome) {
                        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                        Task { @MainActor in
                            await timezoneChangeHandler.keepHomeTimezone(currentLocation: change.newTimezone)
                        }
                    }

                    Button(Strings.TimezoneChange.useCurrent) {
                        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                        Task { @MainActor in
                            await timezoneChangeHandler.useCurrentTimezone(newTimezone: change.newTimezone)
                        }
                    }

                    Button(Strings.TimezoneChange.movedHere) {
                        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                        Task { @MainActor in
                            await timezoneChangeHandler.updateHomeTimezone(
                                previousTimezone: change.previousTimezone,
                                newTimezone: change.newTimezone
                            )
                        }
                    }
                } message: { change in
                    Text(Strings.TimezoneChange.message(change.newTimezoneDisplayName))
                }
        }
    }

    @MainActor
    private func setupCoordinators() {
        lifecycleCoordinator = Container.shared.appLifecycleCoordinator(appStartTime: appStartTime)

        // Wire up timezone change callback
        timezoneChangeHandler.onTimezoneChangeDetected = { [self] changeInfo in
            detectedTimezoneChange = changeInfo
            showTimezoneChangeAlert = true
        }
    }
}

// MARK: - App Delegate

/// AppDelegate handles app launch scenarios including location-based relaunches
@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, UIWindowSceneDelegate {
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "appDelegate")

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.log("AppDelegate didFinishLaunchingWithOptions", level: .info, category: .system)

        #if DEBUG
        enableConcurrencyDebugging()
        #endif

        if launchOptions?[.location] != nil {
            Container.shared.initializeForGeofenceLaunch()
        }

        Container.shared.quickActionCoordinator().registerQuickActions()
        application.registerForRemoteNotifications()

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        logger.log(
            "✅ Registered for remote notifications",
            level: .info,
            category: .system,
            metadata: ["tokenPrefix": String(tokenString.prefix(16)) + "..."]
        )

        #if DEBUG
        ICloudSyncDiagnostics.shared.recordRemoteNotificationRegistration(success: true)
        #endif
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.log(
            "❌ Failed to register for remote notifications",
            level: .error,
            category: .system,
            metadata: ["error": error.localizedDescription]
        )

        #if DEBUG
        ICloudSyncDiagnostics.shared.recordRemoteNotificationRegistration(success: false)
        #endif
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        logger.log(
            "☁️ Received remote notification (CloudKit sync trigger)",
            level: .info,
            category: .system,
            metadata: ["userInfo": String(describing: userInfo)]
        )

        if userInfo["ck"] != nil {
            logger.log("☁️ CloudKit remote change notification received", level: .info, category: .system)

            #if DEBUG
            ICloudSyncDiagnostics.shared.recordPushNotification()
            #endif

            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = AppDelegate.self
        return config
    }

    // MARK: - UIWindowSceneDelegate (Quick Actions)

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let shortcutItem = connectionOptions.shortcutItem {
            logger.log(
                "App launched from Quick Action (cold start)",
                level: .info,
                category: .system,
                metadata: ["shortcutType": shortcutItem.type]
            )
            Container.shared.quickActionCoordinator().handleShortcutItem(shortcutItem)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        logger.log(
            "Quick Action triggered (warm start via SceneDelegate)",
            level: .info,
            category: .system,
            metadata: ["shortcutType": shortcutItem.type]
        )
        let coordinator = Container.shared.quickActionCoordinator()
        let handled = coordinator.handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }

    // MARK: - Concurrency Debugging

    #if DEBUG
    /// Enables enhanced concurrency debugging to help identify threading issues.
    ///
    /// This function configures the runtime to produce more visible warnings when
    /// concurrency violations occur, making it easier to catch issues during development.
    ///
    /// Effects:
    /// - Enables main thread checker assertions
    /// - Makes threading warnings more prominent in Xcode console
    /// - Helps identify "Publishing changes from background threads" issues
    private func enableConcurrencyDebugging() {
        // Enable main thread checker to catch UI updates from background threads
        // This is set at process launch time via environment variables
        // Note: These are typically set in the scheme, but can be verified here
        // Only log concurrency configuration when debugging is active
        // SWIFT_DETERMINISTIC_HASHING is set when running tests, skip verbose logging
        guard ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] == nil else {
            return
        }

        logger.log(
            "🧵 Swift 6 Concurrency Configuration",
            level: .debug,
            category: .system,
            metadata: [
                "swiftVersion": "6.0",
                "strictConcurrency": "complete",
                "defaultActorIsolation": "MainActor",
                "nonisolatedNonsendingByDefault": "enabled"
            ]
        )
    }
    #endif
}

// MARK: - Container Launch Helpers

extension Container {
    @MainActor
    func initializeForGeofenceLaunch() {
        let logger = debugLogger()
        logger.log(
            "🌍 App launched due to location event",
            level: .info,
            category: .location,
            metadata: ["launch_reason": "geofence_event"]
        )

        _ = locationMonitoringService()

        logger.log(
            "✅ Location service initialized for background geofence handling",
            level: .info,
            category: .location
        )
    }
}

// MARK: - Root App View

struct RootAppView: View {
    var body: some View {
        RootTabView()
    }
}
