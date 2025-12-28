import Foundation
import SwiftUI

// swiftlint:disable:next type_body_length
public enum Strings {
    // MARK: - App
    public enum App {
        public static let name = String(localized: "appName")
    }
    
    // MARK: - Navigation
    public enum Navigation {
        public static let overview = String(localized: "navigationOverview")
        public static let habits = String(localized: "navigationHabits")
        public static let stats = String(localized: "navigationStats")
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
        public static let failedToSave = String(localized: "errorFailedToSave")
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
        public static let noHabitsScheduled = String(localized: "emptyNoHabitsScheduled")
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
        public static let photoUpdated = String(localized: "avatar.photo_updated")
        public static let photoRemoved = String(localized: "avatar.photo_removed")
    }

    // MARK: - Profile
    public enum Profile {
        public static let nameUpdated = String(localized: "profile.name_updated")
        public static let genderUpdated = String(localized: "profile.gender_updated")
        public static let ageGroupUpdated = String(localized: "profile.age_group_updated")
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

        // MARK: - Dashboard Accessibility

        public static let dashboardEmptyState = String(localized: "accessibilityDashboardEmptyState")
        public static let chartNoData = String(localized: "accessibilityChartNoData")

        public static func chartDescription(avgCompletion: Int, trend: String) -> String {
            String(format: String(localized: "accessibilityChartDescription"), avgCompletion, trend)
        }

        public static func categoryLabel(name: String, habitCount: Int, completionPercent: Int) -> String {
            let habitText = habitCount == 1 ? "1 habit" : "\(habitCount) habits"
            return String(format: String(localized: "accessibilityCategoryLabel"), name, habitText, completionPercent)
        }

        // MARK: - Today's Summary Accessibility

        public static func progressLabel(completed: Int, total: Int) -> String {
            let percent = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
            return String(format: String(localized: "accessibilityProgressLabel"), completed, total, percent)
        }

        public static func dateLabel(date: String, isToday: Bool) -> String {
            isToday ? String(format: String(localized: "accessibilityDateLabelToday"), date) : date
        }

        public static let previousDayHint = String(localized: "accessibilityPreviousDayHint")
        public static let nextDayHint = String(localized: "accessibilityNextDayHint")
        public static let returnToTodayHint = String(localized: "accessibilityReturnToTodayHint")

        public static func habitRowLabel(name: String, isCompleted: Bool, progress: String?) -> String {
            var label = name
            if isCompleted {
                label += String(localized: "accessibilityHabitCompleted")
            } else if let progress = progress {
                label += ", \(progress)"
            } else {
                label += String(localized: "accessibilityHabitNotCompleted")
            }
            return label
        }

        public static let completedSectionHeader = String(localized: "accessibilityCompletedSectionHeader")
        public static let remainingSectionHeader = String(localized: "accessibilityRemainingSectionHeader")
        public static let noHabitsScheduledAccessibility = String(localized: "accessibilityNoHabitsScheduled")
        public static let loadingHabits = String(localized: "accessibilityLoadingHabits")

        // MARK: - Quick Actions Accessibility

        /// Announcement for habit validation message (e.g., "Morning Workout: Only available on weekdays")
        public static func habitValidationAnnouncement(_ habitName: String, _ message: String) -> String {
            String(format: String(localized: "accessibilityHabitValidationAnnouncement"), habitName, message)
        }

        // MARK: - Welcome Back Accessibility

        /// Summary of synced data for returning users
        public static func syncedDataSummary(habits: Int, categories: Int) -> String {
            String(format: String(localized: "accessibilitySyncedDataSummary"), habits, categories)
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
        public static let timePeriodPicker = String(localized: "dashboardTimePeriodPicker")
        public static let thisWeek = String(localized: "dashboardThisWeek")
        public static let thisMonth = String(localized: "dashboardThisMonth")
        public static let last6Months = String(localized: "dashboardLast6Months")
        public static let lastYear = String(localized: "dashboardLastYear")
        public static let allTime = String(localized: "dashboardAllTime")

        // Schedule optimization messages
        public static let optimizationConsistentPerformance = String(localized: "dashboardOptimizationConsistentPerformance")
        public static let optimizationNearPerfect = String(localized: "dashboardOptimizationNearPerfect")
        public static let optimizationKeepBuilding = String(localized: "dashboardOptimizationKeepBuilding")

        /// Optimization suggestion with day and percentage parameters
        /// Usage: String(format: Strings.Dashboard.optimizationSuggestion, bestDay, gapPercentage, worstDay)
        public static let optimizationSuggestion = String(localized: "dashboardOptimizationSuggestion")
    }
    
    // MARK: - Paywall
    public enum Paywall {
        public static let unlockAdvancedStats = String(localized: "paywall.unlock_advanced_stats")
        public static let statsBlockedMessage = String(localized: "paywall.stats_blocked_message")
        public static let proLabel = String(localized: "paywall.pro_label")
        public static let upgrade = String(localized: "paywall.upgrade")
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

    // MARK: - Habits Assistant
    public enum HabitsAssistant {
        public static let firstVisitTitle = String(localized: "habits_assistant.first_visit.title")
        public static let firstVisitDescription = String(localized: "habits_assistant.first_visit.description")
    }

    // MARK: - Location
    public enum Location {
        // Map Location Picker
        public static let selectLocation = String(localized: "location.select_location")
        public static let searchPlaceholder = String(localized: "location.search_placeholder")
        public static let tapOnMap = String(localized: "location.tap_on_map")
        public static let selectCenterInstruction = String(localized: "location.select_center_instruction")
        public static let configureLocationDetails = String(localized: "location.configure_location_details")

        // Geofence Configuration
        public static let locationDetails = String(localized: "location.location_details")
        public static let locationName = String(localized: "location.location_name")
        public static let locationNameOptional = String(localized: "location.location_name_optional")
        public static let locationNameFooter = String(localized: "location.location_name_footer")
        public static let detectionArea = String(localized: "location.detection_area")
        public static let detectionAreaFooter = String(localized: "location.detection_area_footer")
        public static let radius = String(localized: "location.radius")
        public static let whenToNotify = String(localized: "location.when_to_notify")
        public static let whenToNotifyFooter = String(localized: "location.when_to_notify_footer")
        public static let whenToNotifyEntry = String(localized: "location.when_to_notify_entry")
        public static let whenToNotifyExit = String(localized: "location.when_to_notify_exit")
        public static let whenToNotifyBoth = String(localized: "location.when_to_notify_both")

        // Notification Frequency
        public static let notificationFrequency = String(localized: "location.notification_frequency")
        public static let notificationFrequencyFooter = String(localized: "location.notification_frequency_footer")
        public static let frequencyOncePerDay = String(localized: "location.frequency_once_per_day")
        public static let frequencyEvery15Min = String(localized: "location.frequency_every_15_min")
        public static let frequencyEvery30Min = String(localized: "location.frequency_every_30_min")
        public static let frequencyEveryHour = String(localized: "location.frequency_every_hour")
        public static let frequencyEvery2Hours = String(localized: "location.frequency_every_2_hours")

        // Error Messages
        public static let geofenceRestoreFailed = String(localized: "location.geofence_restore_failed")
    }

    // MARK: - iCloud Sync
    public enum ICloudSync {
        public static let syncedFromCloud = String(localized: "icloud.synced_from_cloud")
        public static let stillSyncing = String(localized: "icloud.still_syncing")
        public static let syncingData = String(localized: "icloud.syncing_data")
        public static let setupTitle = String(localized: "icloud.setup_title")
        public static let setupDescription = String(localized: "icloud.setup_description")
        public static let syncDelayed = String(localized: "icloud.sync_delayed")
    }

    // MARK: - Data Management
    public enum DataManagement {
        public static let deleteAllData = String(localized: "data_management.delete_all_data")
        public static let deleteTitle = String(localized: "data_management.delete_title")
        public static let deleteMessageWithICloud = String(localized: "data_management.delete_message_with_icloud")
        public static let deleteMessageLocalOnly = String(localized: "data_management.delete_message_local_only")
        public static let footerWithICloud = String(localized: "data_management.footer_with_icloud")
        public static let footerLocalOnly = String(localized: "data_management.footer_local_only")
        public static let deleteSuccessMessage = String(localized: "data_management.delete_success_message")
        public static let deleteSyncDelayedMessage = String(localized: "data_management.delete_sync_delayed_message")
        public static let deleteFailedMessage = String(localized: "data_management.delete_failed_message")
    }

    // MARK: - Numeric Habit Log
    public enum NumericHabitLog {
        public static let title = String(localized: "numericHabitLog.title")
        public static let reset = String(localized: "numericHabitLog.reset")
        public static let completeAll = String(localized: "numericHabitLog.completeAll")
        public static let wellDoneExtraMile = String(localized: "numericHabitLog.wellDoneExtraMile")
        public static let loadingCurrentValue = String(localized: "numericHabitLog.loadingCurrentValue")

        // Extra mile phrases (randomly selected)
        public static let extraMileOnFire = String(localized: "numericHabitLog.extraMile.onFire")
        public static let extraMileCrushing = String(localized: "numericHabitLog.extraMile.crushing")
        public static let extraMileAboveBeyond = String(localized: "numericHabitLog.extraMile.aboveBeyond")
        public static let extraMileOverachiever = String(localized: "numericHabitLog.extraMile.overachiever")
        public static let extraMileExtraEffort = String(localized: "numericHabitLog.extraMile.extraEffort")
        public static let extraMileBeyondExpectations = String(localized: "numericHabitLog.extraMile.beyondExpectations")

        public static var extraMilePhrases: [String] {
            [
                extraMileOnFire,
                extraMileCrushing,
                extraMileAboveBeyond,
                extraMileOverachiever,
                extraMileExtraEffort,
                extraMileBeyondExpectations
            ]
        }

        // Accessibility hints
        public static let decreaseHint = String(localized: "numericHabitLog.accessibility.decreaseHint")
        public static let increaseHint = String(localized: "numericHabitLog.accessibility.increaseHint")
        public static let resetHint = String(localized: "numericHabitLog.accessibility.resetHint")
        public static let completeAllHint = String(localized: "numericHabitLog.accessibility.completeAllHint")
        public static let doneHint = String(localized: "numericHabitLog.accessibility.doneHint")

        /// Accessibility label for quick increment button
        public static func quickIncrementLabel(_ amount: String) -> String {
            String(format: String(localized: "numericHabitLog.accessibility.quickIncrementLabel"), amount)
        }

        /// Accessibility hint for quick increment button
        public static func quickIncrementHint(_ amount: String) -> String {
            String(format: String(localized: "numericHabitLog.accessibility.quickIncrementHint"), amount)
        }

        /// Accessibility label for progress circle showing current value, target, and completion
        public static func progressLabel(current: Int, target: Int, isCompleted: Bool) -> String {
            if isCompleted {
                return String(
                    format: String(localized: "numericHabitLog.accessibility.progressCompleted"),
                    current,
                    target
                )
            } else {
                return String(
                    format: String(localized: "numericHabitLog.accessibility.progressInProgress"),
                    current,
                    target
                )
            }
        }
    }

    // MARK: - Common
    public enum Common {
        public static let done = String(localized: "common.done")
        public static let cancel = String(localized: "common.cancel")
        public static let decrease = String(localized: "common.decrease")
        public static let increase = String(localized: "common.increase")
    }

    // MARK: - Uncomplete Habit Sheet
    public enum UncompleteHabitSheet {
        public static let completed = String(localized: "uncompleteHabitSheet.completed")
        public static let markAsNotCompleted = String(localized: "uncompleteHabitSheet.markAsNotCompleted")

        // Accessibility
        public static let markAsNotCompletedHint = String(localized: "uncompleteHabitSheet.accessibility.markAsNotCompletedHint")
        public static let cancelHint = String(localized: "uncompleteHabitSheet.accessibility.cancelHint")

        /// Accessibility label for header combining habit name and completed status
        public static func headerAccessibilityLabel(_ habitName: String) -> String {
            String(format: String(localized: "uncompleteHabitSheet.accessibility.headerLabel"), habitName)
        }

        /// VoiceOver announcement when sheet appears
        public static func screenChangedAnnouncement(_ habitName: String) -> String {
            String(format: String(localized: "uncompleteHabitSheet.accessibility.screenChanged"), habitName)
        }
    }

    // MARK: - Complete Habit Sheet
    public enum CompleteHabitSheet {
        public static let notCompleted = String(localized: "completeHabitSheet.notCompleted")
        public static let markAsCompleted = String(localized: "completeHabitSheet.markAsCompleted")

        // Accessibility
        public static let markAsCompletedHint = String(localized: "completeHabitSheet.accessibility.markAsCompletedHint")
        public static let cancelHint = String(localized: "completeHabitSheet.accessibility.cancelHint")

        /// Accessibility label for header combining habit name and not completed status
        public static func headerAccessibilityLabel(_ habitName: String) -> String {
            String(format: String(localized: "completeHabitSheet.accessibility.headerLabel"), habitName)
        }

        /// VoiceOver announcement when sheet appears
        public static func screenChangedAnnouncement(_ habitName: String) -> String {
            String(format: String(localized: "completeHabitSheet.accessibility.screenChanged"), habitName)
        }
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
