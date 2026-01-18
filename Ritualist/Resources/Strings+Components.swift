import Foundation

// MARK: - Components & UI Strings

extension Strings {
    // MARK: - Components & UI
    public enum Components {
        public static let pro = String(localized: "components.pro")
        public static let export = String(localized: "components.export")
        public static let unlock = String(localized: "components.unlock")
        public static let unlockWithPro = String(localized: "components.unlockWithPro")
        public static let active = String(localized: "components.active")
        public static let inactive = String(localized: "components.inactive")
        public static let predefined = String(localized: "components.predefined")
        public static let loading = String(localized: "components.loading")
        public static let loadingEllipsis = String(localized: "components.loadingEllipsis")
        public static func habitsCount(_ count: Int, _ max: Int) -> String { String(format: String(localized: "components.habitsCount"), count, max) }
        public static let viewHabitDetails = String(localized: "components.viewHabitDetails")
        public static let habitIndicators = String(localized: "components.habitIndicators")
        public static let habitIcons = String(localized: "components.habitIcons")
        public static let habitIconsDescription = String(localized: "components.habitIconsDescription")
        public static let timeRemindersTitle = String(localized: "components.timeReminders.title")
        public static let timeRemindersDesc = String(localized: "components.timeReminders.desc")
        public static let timeRemindersEnabled = String(localized: "components.timeRemindersEnabled")
        public static let locationRemindersTitle = String(localized: "components.locationReminders.title")
        public static let locationRemindersDesc = String(localized: "components.locationReminders.desc")
        public static let locationRemindersEnabled = String(localized: "components.locationRemindersEnabled")
        public static let alwaysAvailableTitle = String(localized: "components.alwaysAvailable.title")
        public static let alwaysAvailableDesc = String(localized: "components.alwaysAvailable.desc")
        public static let scheduledTodayTitle = String(localized: "components.scheduledToday.title")
        public static let scheduledTodayDesc = String(localized: "components.scheduledToday.desc")
        public static let notScheduledTodayTitle = String(localized: "components.notScheduledToday.title")
        public static let notScheduledTodayDesc = String(localized: "components.notScheduledToday.desc")
        public static let iconVisibility = String(localized: "components.iconVisibility")
        public static let iconVisibilityDescription = String(localized: "components.iconVisibilityDescription")
        public static let streakAtRiskTitle = String(localized: "components.streakAtRisk.title")
        public static let streakAtRiskDesc = String(localized: "components.streakAtRisk.desc")
        public static let scheduleIndicatorTitle = String(localized: "components.scheduleIndicator.title")
        public static let scheduleIndicatorDesc = String(localized: "components.scheduleIndicator.desc")
        public static let habitsAssistant = String(localized: "components.habitsAssistant")
        public static let assistantHint = String(localized: "components.assistantHint")
        public static let addHabit = String(localized: "components.addHabit")
        public static let createHabitHint = String(localized: "components.createHabitHint")
    }

    // MARK: - App Header
    public enum AppHeader {
        public static let profileLabel = String(localized: "appHeader.profile.label")
        public static let profileHint = String(localized: "appHeader.profile.hint")
        public static func progressLabel(_ appName: String) -> String { String(format: String(localized: "appHeader.progress.label"), appName) }
        public static func progressPercent(_ percent: Int) -> String { String(format: String(localized: "appHeader.progress.percent"), percent) }
    }

    // MARK: - Toast Notifications
    public enum Toast {
        public static let dismissLabel = String(localized: "toast.dismiss.label")
        public static let dismissHint = String(localized: "toast.dismiss.hint")
        public static let swipeHint = String(localized: "toast.swipe.hint")
    }

    // MARK: - Avatar/Profile Photo
    public enum Avatar {
        public static let profilePhoto = String(localized: "avatar.profile_photo")
        public static let chooseFromPhotos = String(localized: "avatar.choose_from_photos")
        public static let removePhoto = String(localized: "avatar.remove_photo")
        public static let photoUpdated = String(localized: "avatar.photo_updated")
        public static let photoRemoved = String(localized: "avatar.photo_removed")
    }

    // MARK: - Profile
    public enum Profile {
        public static let nameUpdated = String(localized: "profile.name_updated")
        public static let genderUpdated = String(localized: "profile.gender_updated")
        public static let ageGroupUpdated = String(localized: "profile.age_group_updated")
    }

    // MARK: - Tips
    public enum Tips {
        public static let carouselTitle = String(localized: "tips.carousel_title")
        public static let showMore = String(localized: "tips.show_more")
        public static let allTipsTitle = String(localized: "tips.all_tips_title")
        public static let tipDetailTitle = String(localized: "tips.tip_detail_title")
        public static let startSmallTitle = String(localized: "tips.start_small_title")
        public static let startSmallDescription = String(localized: "tips.start_small_description")
        public static let consistencyTitle = String(localized: "tips.consistency_title")
        public static let consistencyDescription = String(localized: "tips.consistency_description")
        public static let trackImmediatelyTitle = String(localized: "tips.track_immediately_title")
        public static let trackImmediatelyDescription = String(localized: "tips.track_immediately_description")
        public static let tapToLogTitle = String(localized: "tips.tapToLog.title")
        public static let tapToLogMessage = String(localized: "tips.tapToLog.message")
        public static let adjustCompletedTitle = String(localized: "tips.adjustCompleted.title")
        public static let adjustCompletedMessage = String(localized: "tips.adjustCompleted.message")
        public static let longPressTitle = String(localized: "tips.longPress.title")
        public static let longPressMessage = String(localized: "tips.longPress.message")
        public static let dailyProgressTitle = String(localized: "tips.dailyProgress.title")
        public static let dailyProgressMessage = String(localized: "tips.dailyProgress.message")
    }

    // MARK: - Notifications
    public enum Notification {
        public static let title = String(localized: "notification.title")
        public static let body = String(localized: "notification.body")
    }
}
