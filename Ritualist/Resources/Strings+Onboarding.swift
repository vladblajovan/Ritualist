import Foundation

// MARK: - Onboarding Strings

extension Strings {
    // MARK: - Onboarding Flow
    public enum Onboarding {
        public static let pageWelcome = String(localized: "onboarding.page.welcome")
        public static let pageTrackHabits = String(localized: "onboarding.page.trackHabits")
        public static let pageMakeItYours = String(localized: "onboarding.page.makeItYours")
        public static let pageLearnImprove = String(localized: "onboarding.page.learnImprove")
        public static let pageFreePro = String(localized: "onboarding.page.freePro")
        public static let pagePermissions = String(localized: "onboarding.page.permissions")
        public static func stepAnnouncement(_ step: Int, _ total: Int, _ title: String) -> String { String(format: String(localized: "onboarding.stepAnnouncement"), step, total, title) }
        public static func pageAnnouncement(_ step: Int) -> String { String(format: String(localized: "onboarding.pageAnnouncement"), step) }
        public static func progressLabel(_ step: Int, _ total: Int) -> String { String(format: String(localized: "onboarding.progressLabel"), step, total) }
        public static func progressPercent(_ percent: Int) -> String { String(format: String(localized: "onboarding.progressPercent"), percent) }
        public static let skip = String(localized: "onboarding.skip")
        public static let skipHint = String(localized: "onboarding.skipHint")
        public static let back = String(localized: "onboarding.back")
        public static let backHint = String(localized: "onboarding.backHint")
        public static let getStarted = String(localized: "onboarding.getStarted")
        public static let continueButton = String(localized: "onboarding.continue")
        public static let completeHint = String(localized: "onboarding.completeHint")
        public static let nextHint = String(localized: "onboarding.nextHint")
        public static let welcomeTitle = String(localized: "onboarding.page1.title")
        public static let welcomeSubtitle = String(localized: "onboarding.page1.subtitle")
        public static let namePlaceholder = String(localized: "onboarding.page1.namePlaceholder")
        public static let genderPlaceholder = String(localized: "onboarding.page1.genderPlaceholder")
        public static let agePlaceholder = String(localized: "onboarding.page1.agePlaceholder")
        public static func nameHint(_ maxLength: Int) -> String { String(format: String(localized: "onboarding.page1.nameHint"), maxLength) }
        public static let trackHabitsTitle = String(localized: "onboarding.page2.title")
        public static let trackHabitsSubtitle = String(localized: "onboarding.page2.subtitle")
        public static func trackHabitsGreeting(_ name: String) -> String { String(format: String(localized: "onboarding.page2.greeting"), name) }
        public static let dailyTrackingTitle = String(localized: "onboarding.page2.dailyTracking.title")
        public static let dailyTrackingDescription = String(localized: "onboarding.page2.dailyTracking.description")
        public static let progressVisualizationTitle = String(localized: "onboarding.page2.progressVisualization.title")
        public static let progressVisualizationDescription = String(localized: "onboarding.page2.progressVisualization.description")
        public static let smartRemindersTitle = String(localized: "onboarding.page2.smartReminders.title")
        public static let smartRemindersDescription = String(localized: "onboarding.page2.smartReminders.description")
        public static let iCloudSyncTitle = String(localized: "onboarding.page2.iCloudSync.title")
        public static let iCloudSyncDescription = String(localized: "onboarding.page2.iCloudSync.description")
        public static let makeItYoursTitle = String(localized: "onboarding.page3.title")
        public static let makeItYoursSubtitle = String(localized: "onboarding.page3.subtitle")
        public static let colorsEmojisTitle = String(localized: "onboarding.page3.colorsEmojis.title")
        public static let colorsEmojisDescription = String(localized: "onboarding.page3.colorsEmojis.description")
        public static let flexibleSchedulingTitle = String(localized: "onboarding.page3.flexibleScheduling.title")
        public static let flexibleSchedulingDescription = String(localized: "onboarding.page3.flexibleScheduling.description")
        public static let setGoalsTitle = String(localized: "onboarding.page3.setGoals.title")
        public static let setGoalsDescription = String(localized: "onboarding.page3.setGoals.description")
        public static let travelFriendlyTitle = String(localized: "onboarding.page3.travelFriendly.title")
        public static let travelFriendlyDescription = String(localized: "onboarding.page3.travelFriendly.description")
        public static let learnImproveTitle = String(localized: "onboarding.page4.title")
        public static let learnImproveSubtitle = String(localized: "onboarding.page4.subtitle")
        public static let scienceBasedTipsTitle = String(localized: "onboarding.page4.scienceBasedTips.title")
        public static let scienceBasedTipsDescription = String(localized: "onboarding.page4.scienceBasedTips.description")
        public static let trackProgressTitle = String(localized: "onboarding.page4.trackProgress.title")
        public static let trackProgressDescription = String(localized: "onboarding.page4.trackProgress.description")
        public static let stayMotivatedTitle = String(localized: "onboarding.page4.stayMotivated.title")
        public static let stayMotivatedDescription = String(localized: "onboarding.page4.stayMotivated.description")
        public static let travelInsightsTitle = String(localized: "onboarding.page4.travelInsights.title")
        public static let travelInsightsDescription = String(localized: "onboarding.page4.travelInsights.description")
        public static let quickTour = String(localized: "onboarding.page6.quickTour")
        public static let quickTourDescription = String(localized: "onboarding.page6.quickTourDescription")
        public static let skipQuickTourTitle = String(localized: "onboarding.page6.skipQuickTourTitle")
        public static let skipQuickTourMessage = String(localized: "onboarding.page6.skipQuickTourMessage")
        public static let keepTour = String(localized: "onboarding.page6.keepTour")
        public static let notificationsTitle = String(localized: "onboarding.page6.notifications.title")
        public static let notificationsDescription = String(localized: "onboarding.page6.notifications.description")
        public static let locationTitle = String(localized: "onboarding.page6.location.title")
        public static let locationDescription = String(localized: "onboarding.page6.location.description")
        public static let enable = String(localized: "onboarding.page6.enable")
        public static let enabled = String(localized: "onboarding.page6.enabled")
        public static let notEnabled = String(localized: "onboarding.page6.notEnabled")
        public static let preparingExperience = String(localized: "onboarding.appLaunch.preparingExperience")
        public static let onlyTakesMoment = String(localized: "onboarding.appLaunch.onlyTakesMoment")
        public static let loading = String(localized: "onboarding.appLaunch.loading")
        public static let loadingAccessibility = String(localized: "onboarding.appLaunch.loadingAccessibility")
        public static let preparingAccessibility = String(localized: "onboarding.appLaunch.preparingAccessibility")
        public static let welcomeBackWithName = String(localized: "onboarding.welcomeBack.withName")
        public static let welcomeBackWithoutName = String(localized: "onboarding.welcomeBack.withoutName")
        public static let dataSyncedFromICloud = String(localized: "onboarding.welcomeBack.dataSynced")
        public static func habitsSynced(_ count: Int) -> String { String(format: String(localized: "onboarding.welcomeBack.habitsSynced"), count) }
        public static func categoriesSynced(_ count: Int) -> String { String(format: String(localized: "onboarding.welcomeBack.categoriesSynced"), count) }
        public static let profileRestored = String(localized: "onboarding.welcomeBack.profileRestored")
        public static let letsSetUpDevice = String(localized: "onboarding.welcomeBack.letsSetUpDevice")
        public static let continueToSetUp = String(localized: "onboarding.welcomeBack.continueToSetUp")
        public static let stepWelcomeBack = String(localized: "onboarding.returning.stepWelcomeBack")
        public static let stepCompleteProfile = String(localized: "onboarding.returning.stepCompleteProfile")
        public static let stepSetUpDevice = String(localized: "onboarding.returning.stepSetUpDevice")
        public static let unexpectedError = String(localized: "onboarding.returning.unexpectedError")
        public static let enablePermissionsSubtitle = String(localized: "onboarding.returning.enablePermissionsSubtitle")
        public static let enableLaterInSettings = String(localized: "onboarding.returning.enableLaterInSettings")
        public static let helpPersonalize = String(localized: "onboarding.returning.helpPersonalize")
        public static let enterNameToContinue = String(localized: "onboarding.returning.enterNameToContinue")
        public static let continueToPermissions = String(localized: "onboarding.returning.continueToPermissions")
    }

    // MARK: - Onboarding Premium Comparison
    public enum OnboardingPremium {
        public static let title = String(localized: "onboarding.premium.title")
        public static let subtitle = String(localized: "onboarding.premium.subtitle")
        public static let freeTier = String(localized: "onboarding.premium.free_tier")
        public static let proTier = String(localized: "onboarding.premium.pro_tier")
        public static let fiveHabits = String(localized: "onboarding.premium.five_habits")
        public static let dailyTracking = String(localized: "onboarding.premium.daily_tracking")
        public static let basicNotifications = String(localized: "onboarding.premium.basic_notifications")
        public static let tipsInsights = String(localized: "onboarding.premium.tips_insights")
        public static let iCloudSync = String(localized: "onboarding.premium.icloud_sync")
        public static let unlimitedHabits = String(localized: "onboarding.premium.unlimited_habits")
        public static let advancedAnalytics = String(localized: "onboarding.premium.advanced_analytics")
        public static let customReminders = String(localized: "onboarding.premium.custom_reminders")
        public static let dataExport = String(localized: "onboarding.premium.data_export")
        public static let footer = String(localized: "onboarding.premium.footer")
    }

    // MARK: - Onboarding Permissions
    public enum OnboardingPermissions {
        public static let title = String(localized: "onboarding.permissions.title")
        public static let subtitle = String(localized: "onboarding.permissions.subtitle")
        public static let enableNotifications = String(localized: "onboarding.permissions.enable_notifications")
        public static let enableLocation = String(localized: "onboarding.permissions.enable_location")
        public static let notificationsGranted = String(localized: "onboarding.permissions.notifications_granted")
        public static let locationGranted = String(localized: "onboarding.permissions.location_granted")
        public static let notificationsDescription = String(localized: "onboarding.permissions.notifications_description")
        public static let locationDescription = String(localized: "onboarding.permissions.location_description")
        public static let skipForNow = String(localized: "onboarding.permissions.skip_for_now")
    }
}
