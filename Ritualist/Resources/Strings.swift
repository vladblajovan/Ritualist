import Foundation
import SwiftUI

/// Centralized localized strings using String Catalogs (.xcstrings)
/// This provides type-safe access to all localized strings in the app
public enum Strings {
    
    // MARK: - App
    public enum App {
        public static let name = String(localized: "appName")
    }
    
    // MARK: - Navigation
    public enum Navigation {
        public static let overview = String(localized: "navigationOverview")
        public static let habits = String(localized: "navigationHabits")
        public static let dashboard = String(localized: "navigationDashboard")
        public static let settings = String(localized: "navigationSettings")
        public static let editHabit = String(localized: "navigationEditHabit")
        public static let newHabit = String(localized: "navigationNewHabit")
    }
    
    // MARK: - Buttons
    public enum Button {
        public static let save = String(localized: "buttonSave")
        public static let cancel = String(localized: "buttonCancel")
        public static let delete = String(localized: "buttonDelete")
        public static let retry = String(localized: "buttonRetry")
        public static let done = String(localized: "buttonDone")
        public static let activate = String(localized: "activate")
        public static let deactivate = String(localized: "deactivate")
    }
    
    // MARK: - Loading States
    public enum Loading {
        public static let initializing = String(localized: "loadingInitializing")
        public static let habits = String(localized: "loadingHabits")
        public static let settings = String(localized: "loadingSettings")
        public static let habit = String(localized: "loadingHabit")
        public static let saving = String(localized: "loadingSaving")
        public static let calculatingStreaks = String(localized: "loadingCalculatingStreaks")
        public static let processingImage = String(localized: "loadingProcessingImage")
    }
    
    // MARK: - Status Messages
    public enum Status {
        public static let creating = String(localized: "statusCreating")
        public static let updating = String(localized: "statusUpdating")
        public static let deleting = String(localized: "statusDeleting")
        public static let active = String(localized: "statusActive")
        public static let inactive = String(localized: "statusInactive")
    }
    
    // MARK: - Error Messages
    public enum Error {
        public static let failedInitialize = String(localized: "errorFailedInitialize")
        public static let failedLoadHabits = String(localized: "errorFailedLoadHabits")
        public static let failedLoadSettings = String(localized: "errorFailedLoadSettings")
        public static let failedLoadHabit = String(localized: "errorFailedLoadHabit")
        public static let unableSetupOverview = String(localized: "errorUnableSetupOverview")
        public static let unableSetupHabits = String(localized: "errorUnableSetupHabits")
        public static let unableSetupSettings = String(localized: "errorUnableSetupSettings")
    }
    
    // MARK: - Empty States
    public enum EmptyState {
        public static let noActiveHabits = String(localized: "emptyNoActiveHabits")
        public static let createHabitsToStart = String(localized: "emptyCreateHabitsToStart")
        public static let noHabitsYet = String(localized: "emptyNoHabitsYet")
        public static let tapPlusToCreate = String(localized: "emptyTapPlusToCreate")
        public static let noHabitSelected = String(localized: "emptyNoHabitSelected")
        public static let tapHabitToView = String(localized: "emptyTapHabitToView")
    }
    
    // MARK: - Form Labels
    public enum Form {
        public static let basicInformation = String(localized: "formBasicInformation")
        public static let schedule = String(localized: "formSchedule")
        public static let appearance = String(localized: "formAppearance")
        public static let name = String(localized: "formName")
        public static let habitName = String(localized: "formHabitName")
        public static let type = String(localized: "formType")
        public static let yesNo = String(localized: "formYesNo")
        public static let count = String(localized: "formCount")
        public static let unit = String(localized: "formUnit")
        public static let unitPlaceholder = String(localized: "formUnitPlaceholder")
        public static let dailyTarget = String(localized: "formDailyTarget")
        public static let target = String(localized: "formTarget")
        public static let frequency = String(localized: "formFrequency")
        public static let daily = String(localized: "formDaily")
        public static let specificDays = String(localized: "formSpecificDays")
        public static let timesPerWeek = String(localized: "formTimesPerWeek")
        public static let timesPerWeekLabel = String(localized: "formTimesPerWeekLabel")
        public static let selectDays = String(localized: "formSelectDays")
        public static let emoji = String(localized: "formEmoji")
        public static let color = String(localized: "formColor")
    }
    
    // MARK: - Validation Messages
    public enum Validation {
        public static let nameRequired = String(localized: "validationNameRequired")
        public static let unitRequired = String(localized: "validationUnitRequired")
        public static let targetGreaterThanZero = String(localized: "validationTargetGreaterThanZero")
        public static let selectAtLeastOneDay = String(localized: "validationSelectAtLeastOneDay")
        public static let categoryRequired = String(localized: "validationCategoryRequired")
    }
    
    // MARK: - Settings
    public enum Settings {
        public static let profile = String(localized: "settingsProfile")
        public static let firstDayOfWeek = String(localized: "settingsFirstDayOfWeek")
        public static let appearanceSetting = String(localized: "settingsAppearance")
        public static let followSystem = String(localized: "settingsFollowSystem")
        public static let light = String(localized: "settingsLight")
        public static let dark = String(localized: "settingsDark")
        public static let settingsSaved = String(localized: "settingsSaved")
        public static let notifications = String(localized: "settingsNotifications")
        public static let notificationPermission = String(localized: "settingsNotificationPermission")
        public static let notificationsEnabled = String(localized: "settingsNotificationsEnabled")
        public static let notificationsDisabled = String(localized: "settingsNotificationsDisabled")
        public static let enable = String(localized: "settingsEnable")
        public static let openSettings = String(localized: "settingsOpenSettings")
    }
    
    // MARK: - Days of Week
    public enum DayOfWeek {
        public static let monday = String(localized: "dayMonday")
        public static let tuesday = String(localized: "dayTuesday")
        public static let wednesday = String(localized: "dayWednesday")
        public static let thursday = String(localized: "dayThursday")
        public static let friday = String(localized: "dayFriday")
        public static let saturday = String(localized: "daySaturday")
        public static let sunday = String(localized: "daySunday")
        public static let unknown = String(localized: "dayUnknown")
        
        // Day abbreviations
        public static let mon = String(localized: "dayMon")
        public static let tue = String(localized: "dayTue")
        public static let wed = String(localized: "dayWed")
        public static let thu = String(localized: "dayThu")
        public static let fri = String(localized: "dayFri")
        public static let sat = String(localized: "daySat")
        public static let sun = String(localized: "daySun")
    }
    
    // MARK: - Overview/Calendar
    public enum Overview {
        public static let instructions = String(localized: "overviewInstructions")
        public static let yourHabits = String(localized: "overviewYourHabits")
        public static let calendar = String(localized: "overviewCalendar")
        public static let stats = String(localized: "overviewStats")
        public static let current = String(localized: "overviewCurrent")
        public static let best = String(localized: "overviewBest")
        
        // Dynamic strings with pluralization
        public static func dayPlural(_ count: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString("overviewDayPlural", comment: "Streak count with proper pluralization"),
                count
            )
        }
        
        public static let daySingular = String(localized: "overviewDaySingular")
        public static let dayPlural = String(localized: "overviewDayPluralStatic")
    }
    
    // MARK: - Calendar
    public enum Calendar {
        public static let today = String(localized: "calendarToday")
    }
    
    // MARK: - Confirmation Dialogs
    public enum Dialog {
        public static let deleteHabit = String(localized: "dialogDeleteHabit")
        public static let cannotUndo = String(localized: "dialogCannotUndo")
        
        // Dynamic string with habit name interpolation
        public static func deleteHabitMessage(_ habitName: String) -> String {
            String(format: String(localized: "dialogDeleteHabitMessage"), habitName)
        }
    }
    
    // MARK: - Avatar/Profile Photo
    public enum Avatar {
        public static let profilePhoto = String(localized: "avatar.profile_photo")
        public static let chooseFromPhotos = String(localized: "avatar.choose_from_photos")
        public static let removePhoto = String(localized: "avatar.remove_photo")
    }
    
    // MARK: - Notifications
    public enum Notification {
        public static let title = String(localized: "notification.title")
        public static let body = String(localized: "notification.body")
    }
    
    // MARK: - Accessibility
    public enum Accessibility {
        public static let previousMonth = String(localized: "accessibilityPreviousMonth")
        public static let nextMonth = String(localized: "accessibilityNextMonth")
        public static let addHabit = String(localized: "accessibilityAddHabit")
        public static let goToToday = String(localized: "accessibilityGoToToday")
        
        // Dynamic accessibility labels
        public static func calendarDay(_ day: String) -> String {
            String(format: String(localized: "accessibilityCalendarDay"), day)
        }
        
        public static func habitLogged(_ date: String) -> String {
            String(format: String(localized: "accessibilityHabitLogged"), date)
        }
        
        public static func habitNotLogged(_ date: String) -> String {
            String(format: String(localized: "accessibilityHabitNotLogged"), date)
        }
        
        public static func habitChip(_ habitName: String) -> String {
            String(format: String(localized: "accessibilityHabitChip"), habitName)
        }
        
        public static func monthHeader(_ monthYear: String) -> String {
            String(format: String(localized: "accessibilityMonthHeader"), monthYear)
        }
        
        public static func deleteHabit(_ habitName: String) -> String {
            String(format: String(localized: "accessibilityDeleteHabit"), habitName)
        }
        
        public static func habitStatus(_ habitName: String, _ status: String) -> String {
            String(format: String(localized: "accessibilityHabitStatus"), habitName, status)
        }
        
        public static func streakInfo(_ currentStreak: String, _ bestStreak: String) -> String {
            String(format: String(localized: "accessibilityStreakInfo"), currentStreak, bestStreak)
        }
    }
    
    // MARK: - Number Formatting
    public enum Format {
        public static func habitValueWithUnit(_ value: String, _ unit: String) -> String {
            String(format: String(localized: "format.habit_value_with_unit"), value, unit)
        }
        
        public static func progressPercentage(_ percentage: String) -> String {
            String(format: String(localized: "format.progress_percentage"), percentage)
        }
    }
    
    // MARK: - Tips
    public enum Tips {
        public static let carouselTitle = String(localized: "tips.carousel_title")
        public static let showMore = String(localized: "tips.show_more")
        public static let allTipsTitle = String(localized: "tips.all_tips_title")
        public static let tipDetailTitle = String(localized: "tips.tip_detail_title")
        
        // Predefined tip content
        public static let startSmallTitle = String(localized: "tips.start_small_title")
        public static let startSmallDescription = String(localized: "tips.start_small_description")
        public static let consistencyTitle = String(localized: "tips.consistency_title")
        public static let consistencyDescription = String(localized: "tips.consistency_description")
        public static let trackImmediatelyTitle = String(localized: "tips.track_immediately_title")
        public static let trackImmediatelyDescription = String(localized: "tips.track_immediately_description")
    }
    
    // MARK: - Dashboard
    public enum Dashboard {
        public static let title = String(localized: "dashboardTitle")
        public static let completionStats = String(localized: "dashboardCompletionStats")
        public static let totalHabits = String(localized: "dashboardTotalHabits")
        public static let completedHabits = String(localized: "dashboardCompletedHabits")
        public static let overallCompletion = String(localized: "dashboardOverallCompletion")
        public static let weeklyProgress = String(localized: "dashboardWeeklyProgress")
        public static let monthlyProgress = String(localized: "dashboardMonthlyProgress")
        public static let consistencyScore = String(localized: "dashboardConsistencyScore")
        public static let topPerformers = String(localized: "dashboardTopPerformers")
        public static let needsImprovement = String(localized: "dashboardNeedsImprovement")
        public static let noDataAvailable = String(localized: "dashboardNoDataAvailable")
        public static let startTrackingMessage = String(localized: "dashboardStartTrackingMessage")
        
        // Time period selectors
        public static let thisWeek = String(localized: "dashboardThisWeek")
        public static let thisMonth = String(localized: "dashboardThisMonth")
        public static let last6Months = String(localized: "dashboardLast6Months")
        public static let lastYear = String(localized: "dashboardLastYear")
        public static let allTime = String(localized: "dashboardAllTime")
    }
    
    // MARK: - Paywall
    public enum Paywall {
        public static let unlockAdvancedStats = String(localized: "paywall.unlock_advanced_stats")
        public static let statsBlockedMessage = String(localized: "paywall.stats_blocked_message")
        public static let proLabel = String(localized: "paywall.pro_label")
        public static let upgrade = String(localized: "paywall.upgrade")
    }
}

// MARK: - SwiftUI Extensions
extension Text {
    /// Create Text with localized string key
    public init(localizedKey key: LocalizedStringKey) {
        self.init(key)
    }
}

// MARK: - Localization Helpers
extension String {
    /// Create localized string with fallback
    public init(localized key: String, defaultValue: String = "") {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            self.init(localized: String.LocalizationValue(key))
        } else {
            self = NSLocalizedString(key, comment: "")
        }
    }
}