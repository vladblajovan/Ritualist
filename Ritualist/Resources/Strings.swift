import Foundation
import SwiftUI

/// Centralized localized strings using String Catalogs (.xcstrings)
/// This provides type-safe access to all localized strings in the app
public enum Strings {
    
    // MARK: - App
    public enum App {
        public static let name = String(localized: "app.name")
    }
    
    // MARK: - Navigation
    public enum Navigation {
        public static let overview = String(localized: "navigation.overview")
        public static let habits = String(localized: "navigation.habits")
        public static let settings = String(localized: "navigation.settings")
        public static let editHabit = String(localized: "navigation.edit_habit")
        public static let newHabit = String(localized: "navigation.new_habit")
    }
    
    // MARK: - Buttons
    public enum Button {
        public static let save = String(localized: "button.save")
        public static let cancel = String(localized: "button.cancel")
        public static let delete = String(localized: "button.delete")
        public static let retry = String(localized: "button.retry")
        public static let done = String(localized: "button.done")
        public static let activate = String(localized: "Activate")
        public static let deactivate = String(localized: "Deactivate")
    }
    
    // MARK: - Loading States
    public enum Loading {
        public static let initializing = String(localized: "loading.initializing")
        public static let habits = String(localized: "loading.habits")
        public static let settings = String(localized: "loading.settings")
        public static let habit = String(localized: "loading.habit")
        public static let saving = String(localized: "loading.saving")
        public static let calculatingStreaks = String(localized: "loading.calculating_streaks")
        public static let processingImage = String(localized: "loading.processing_image")
    }
    
    // MARK: - Status Messages
    public enum Status {
        public static let creating = String(localized: "status.creating")
        public static let updating = String(localized: "status.updating")
        public static let deleting = String(localized: "status.deleting")
        public static let active = String(localized: "status.active")
        public static let inactive = String(localized: "status.inactive")
    }
    
    // MARK: - Error Messages
    public enum Error {
        public static let failedInitialize = String(localized: "error.failed_initialize")
        public static let failedLoadHabits = String(localized: "error.failed_load_habits")
        public static let failedLoadSettings = String(localized: "error.failed_load_settings")
        public static let failedLoadHabit = String(localized: "error.failed_load_habit")
        public static let unableSetupOverview = String(localized: "error.unable_setup_overview")
        public static let unableSetupHabits = String(localized: "error.unable_setup_habits")
        public static let unableSetupSettings = String(localized: "error.unable_setup_settings")
    }
    
    // MARK: - Empty States
    public enum EmptyState {
        public static let noActiveHabits = String(localized: "empty.no_active_habits")
        public static let createHabitsToStart = String(localized: "empty.create_habits_to_start")
        public static let noHabitsYet = String(localized: "empty.no_habits_yet")
        public static let tapPlusToCreate = String(localized: "empty.tap_plus_to_create")
        public static let noHabitSelected = String(localized: "empty.no_habit_selected")
        public static let tapHabitToView = String(localized: "empty.tap_habit_to_view")
    }
    
    // MARK: - Form Labels
    public enum Form {
        public static let basicInformation = String(localized: "form.basic_information")
        public static let schedule = String(localized: "form.schedule")
        public static let appearance = String(localized: "form.appearance")
        public static let name = String(localized: "form.name")
        public static let habitName = String(localized: "form.habit_name")
        public static let type = String(localized: "form.type")
        public static let yesNo = String(localized: "form.yes_no")
        public static let count = String(localized: "form.count")
        public static let unit = String(localized: "form.unit")
        public static let unitPlaceholder = String(localized: "form.unit_placeholder")
        public static let dailyTarget = String(localized: "form.daily_target")
        public static let target = String(localized: "form.target")
        public static let frequency = String(localized: "form.frequency")
        public static let daily = String(localized: "form.daily")
        public static let specificDays = String(localized: "form.specific_days")
        public static let timesPerWeek = String(localized: "form.times_per_week")
        public static let timesPerWeekLabel = String(localized: "form.times_per_week_label")
        public static let selectDays = String(localized: "form.select_days")
        public static let emoji = String(localized: "form.emoji")
        public static let color = String(localized: "form.color")
    }
    
    // MARK: - Validation Messages
    public enum Validation {
        public static let nameRequired = String(localized: "validation.name_required")
        public static let unitRequired = String(localized: "validation.unit_required")
        public static let targetGreaterThanZero = String(localized: "validation.target_greater_than_zero")
        public static let selectAtLeastOneDay = String(localized: "validation.select_at_least_one_day")
    }
    
    // MARK: - Settings
    public enum Settings {
        public static let profile = String(localized: "settings.profile")
        public static let firstDayOfWeek = String(localized: "settings.first_day_of_week")
        public static let appearanceSetting = String(localized: "settings.appearance")
        public static let followSystem = String(localized: "settings.follow_system")
        public static let light = String(localized: "settings.light")
        public static let dark = String(localized: "settings.dark")
        public static let settingsSaved = String(localized: "settings.saved")
        public static let notifications = String(localized: "settings.notifications")
        public static let notificationPermission = String(localized: "settings.notification_permission")
        public static let notificationsEnabled = String(localized: "settings.notifications_enabled")
        public static let notificationsDisabled = String(localized: "settings.notifications_disabled")
        public static let enable = String(localized: "settings.enable")
        public static let openSettings = String(localized: "settings.open_settings")
    }
    
    // MARK: - Days of Week
    public enum DayOfWeek {
        public static let monday = String(localized: "day.monday")
        public static let tuesday = String(localized: "day.tuesday")
        public static let wednesday = String(localized: "day.wednesday")
        public static let thursday = String(localized: "day.thursday")
        public static let friday = String(localized: "day.friday")
        public static let saturday = String(localized: "day.saturday")
        public static let sunday = String(localized: "day.sunday")
        public static let unknown = String(localized: "day.unknown")
        
        // Day abbreviations
        public static let mon = String(localized: "day.mon")
        public static let tue = String(localized: "day.tue")
        public static let wed = String(localized: "day.wed")
        public static let thu = String(localized: "day.thu")
        public static let fri = String(localized: "day.fri")
        public static let sat = String(localized: "day.sat")
        public static let sun = String(localized: "day.sun")
    }
    
    // MARK: - Overview/Calendar
    public enum Overview {
        public static let instructions = String(localized: "overview.instructions")
        public static let yourHabits = String(localized: "overview.your_habits")
        public static let calendar = String(localized: "overview.calendar")
        public static let stats = String(localized: "overview.stats")
        public static let current = String(localized: "overview.current")
        public static let best = String(localized: "overview.best")
        
        // Dynamic strings with pluralization
        public static func dayPlural(_ count: Int) -> String {
            String(localized: "overview.day_plural", defaultValue: "\(count) day(s)")
        }
    }
    
    // MARK: - Calendar
    public enum Calendar {
        public static let today = String(localized: "calendar.today")
    }
    
    // MARK: - Confirmation Dialogs
    public enum Dialog {
        public static let deleteHabit = String(localized: "dialog.delete_habit")
        public static let cannotUndo = String(localized: "dialog.cannot_undo")
        
        // Dynamic string with habit name interpolation
        public static func deleteHabitMessage(_ habitName: String) -> String {
            String(format: String(localized: "dialog.delete_habit_message"), habitName)
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
        public static let previousMonth = String(localized: "accessibility.previous_month")
        public static let nextMonth = String(localized: "accessibility.next_month")
        public static let addHabit = String(localized: "accessibility.add_habit")
        public static let goToToday = String(localized: "accessibility.go_to_today")
        
        // Dynamic accessibility labels
        public static func calendarDay(_ day: String) -> String {
            String(format: String(localized: "accessibility.calendar_day"), day)
        }
        
        public static func habitLogged(_ date: String) -> String {
            String(format: String(localized: "accessibility.habit_logged"), date)
        }
        
        public static func habitNotLogged(_ date: String) -> String {
            String(format: String(localized: "accessibility.habit_not_logged"), date)
        }
        
        public static func habitChip(_ habitName: String) -> String {
            String(format: String(localized: "accessibility.habit_chip"), habitName)
        }
        
        public static func monthHeader(_ monthYear: String) -> String {
            String(format: String(localized: "accessibility.month_header"), monthYear)
        }
        
        public static func deleteHabit(_ habitName: String) -> String {
            String(format: String(localized: "accessibility.delete_habit"), habitName)
        }
        
        public static func habitStatus(_ habitName: String, _ status: String) -> String {
            String(format: String(localized: "accessibility.habit_status"), habitName, status)
        }
        
        public static func streakInfo(_ currentStreak: String, _ bestStreak: String) -> String {
            String(format: String(localized: "accessibility.streak_info"), currentStreak, bestStreak)
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