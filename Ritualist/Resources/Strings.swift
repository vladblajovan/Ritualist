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
        public static let preparingExperience = String(localized: "loadingPreparingExperience")
        public static let onlyTakeAMoment = String(localized: "loadingOnlyTakeAMoment")
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
        public static let title = String(localized: "settingsTitle")
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

        // Section headers
        public static let sectionDebug = String(localized: "settingsSectionDebug")
        public static let sectionAppearance = String(localized: "settingsSectionAppearance")
        public static let sectionTimezone = String(localized: "settingsSectionTimezone")
        public static let sectionSupport = String(localized: "settingsSectionSupport")
        public static let sectionLegal = String(localized: "settingsSectionLegal")
        public static let sectionAbout = String(localized: "settingsSectionAbout")

        // Debug menu
        public static let debugMenu = String(localized: "settingsDebugMenu")
        public static let debugMenuSubtitle = String(localized: "settingsDebugMenuSubtitle")

        // Timezone
        public static let timezoneSettings = String(localized: "settingsTimezoneSettings")

        // Support
        public static let contactSupport = String(localized: "settingsContactSupport")
        public static let helpAndFAQ = String(localized: "settingsHelpAndFAQ")

        // Legal
        public static let privacyPolicy = String(localized: "settingsPrivacyPolicy")
        public static let termsOfService = String(localized: "settingsTermsOfService")

        // About
        public static let version = String(localized: "settingsVersion")
        public static let build = String(localized: "settingsBuild")
        public static let acknowledgements = String(localized: "settingsAcknowledgements")

        // Error states
        public static let failedToLoad = String(localized: "settingsFailedToLoad")

        // Account Section
        public static let gender = String(localized: "settingsGender")
        public static let ageGroup = String(localized: "settingsAgeGroup")
        public static let updating = String(localized: "settingsUpdating")
        public static let editProfilePicture = String(localized: "settingsEditProfilePicture")
        public static let changeAvatarHint = String(localized: "settingsChangeAvatarHint")
        public static let yourName = String(localized: "settingsYourName")
        public static let enterDisplayName = String(localized: "settingsEnterDisplayName")
        public static let genderHint = String(localized: "settingsGenderHint")
        public static let ageGroupHint = String(localized: "settingsAgeGroupHint")

        // Permissions Section
        public static let sectionPermissions = String(localized: "settingsSectionPermissions")
        public static let location = String(localized: "settingsLocation")
        public static let requestNotificationPermission = String(localized: "settingsRequestNotificationPermission")
        public static let enableNotificationsHint = String(localized: "settingsEnableNotificationsHint")
        public static let openNotificationSettings = String(localized: "settingsOpenNotificationSettings")
        public static let opensSettingsApp = String(localized: "settingsOpensSettingsApp")
        public static let requestLocationPermission = String(localized: "settingsRequestLocationPermission")
        public static let enableLocationHint = String(localized: "settingsEnableLocationHint")
        public static let openLocationSettings = String(localized: "settingsOpenLocationSettings")

        // Social Media Section
        public static let sectionConnectWithUs = String(localized: "settingsSectionConnectWithUs")
        public static let instagram = String(localized: "settingsInstagram")
        public static let xTwitter = String(localized: "settingsXTwitter")
        public static let tiktok = String(localized: "settingsTikTok")
        public static let visitWebsite = String(localized: "settingsVisitWebsite")

        // Acknowledgements
        public static let acknowledgementsIntro = String(localized: "settingsAcknowledgementsIntro")
        public static let factoryDescription = String(localized: "settingsFactoryDescription")
        public static let viewOnGitHub = String(localized: "settingsViewOnGitHub")
    }

    // MARK: - Timezone Settings
    public enum Timezone {
        public static let title = String(localized: "timezoneTitle")
        public static let intro = String(localized: "timezoneIntro")
        public static let errorTitle = String(localized: "timezoneErrorTitle")
        public static let failedToUpdateMode = String(localized: "timezoneFailedToUpdateMode")
        public static let failedToUpdateTimezone = String(localized: "timezoneFailedToUpdateTimezone")

        // Travel Status
        public static let youAreTraveling = String(localized: "timezoneYouAreTraveling")
        public static let travelingDescription = String(localized: "timezoneTravelingDescription")

        // Display Mode
        public static let displayMode = String(localized: "timezoneDisplayMode")
        public static let currentLocation = String(localized: "timezoneCurrentLocation")
        public static let homeLocation = String(localized: "timezoneHomeLocation")
        public static let homeTimezone = String(localized: "timezoneHomeTimezone")

        // Sections
        public static let habitTracking = String(localized: "timezoneHabitTracking")
        public static let habitTrackingFooter = String(localized: "timezoneHabitTrackingFooter")
        public static let timezoneInfo = String(localized: "timezoneInfo")
        public static let timezoneInfoFooter = String(localized: "timezoneInfoFooter")

        // Info Labels
        public static let currentTimezone = String(localized: "timezoneCurrentTimezone")
        public static let usingForHabits = String(localized: "timezoneUsingForHabits")

        // Mode Explanations
        public static func currentModeExplanation(_ timezone: String) -> String {
            String(format: String(localized: "timezoneCurrentModeExplanation"), timezone)
        }
        public static func homeModeExplanation(_ timezone: String) -> String {
            String(format: String(localized: "timezoneHomeModeExplanation"), timezone)
        }
        public static let customModeExplanation = String(localized: "timezoneCustomModeExplanation")

        // Picker
        public static let selectHomeTimezone = String(localized: "timezoneSelectHomeTimezone")
        public static let searchTimezones = String(localized: "timezoneSearchTimezones")
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

        // Deactivate Habits Banner
        public static let tooManyActiveHabits = String(localized: "overview.tooManyActiveHabits")
        public static func deactivateHabitsOrUpgrade(_ count: Int) -> String {
            String(format: String(localized: "overview.deactivateHabitsOrUpgrade"), count)
        }
        public static let manageHabits = String(localized: "overview.manageHabits")
        public static let upgrade = String(localized: "overview.upgrade")

        // Streak Detail Sheet
        public static let daysActive = String(localized: "overview.daysActive")
        public static let achievement = String(localized: "overview.achievement")
        public static let howStreaksWork = String(localized: "overview.howStreaksWork")
        public static let daysActiveExplanation = String(localized: "overview.daysActiveExplanation")
        public static let achievementLevelsExplanation = String(localized: "overview.achievementLevelsExplanation")
        public static let streakBuilding = String(localized: "overview.streakBuilding")
        public static let streakStrong = String(localized: "overview.streakStrong")
        public static let streakFireMaster = String(localized: "overview.streakFireMaster")
        public static let streakDetails = String(localized: "overview.streakDetails")

        // Personality Insights
        public static let personalityInsights = String(localized: "overview.personalityInsights")
        public static func basedOnProfile(_ trait: String) -> String {
            String(format: String(localized: "overview.basedOnProfile"), trait)
        }
        public static let dataReadyForAnalysis = String(localized: "overview.dataReadyForAnalysis")
        public static let unlockWithPro = String(localized: "overview.unlockWithPro")
        public static let insightsFromPreviousAnalysis = String(localized: "overview.insightsFromPreviousAnalysis")
        public static let completeRequirements = String(localized: "overview.completeRequirements")

        // Today's Summary Card
        public static let reminderIcons = String(localized: "overview.reminderIcons")
        public static let reminderIconsDescription = String(localized: "overview.reminderIconsDescription")
        public static let scheduleIcons = String(localized: "overview.scheduleIcons")
        public static let scheduleIconsDescription = String(localized: "overview.scheduleIconsDescription")
        public static let streakIndicator = String(localized: "overview.streakIndicator")
        public static let streakIndicatorDescription = String(localized: "overview.streakIndicatorDescription")
        public static let habitStatus = String(localized: "overview.habitStatus")
        public static let streakAtRisk = String(localized: "overview.streakAtRisk")
        public static let streakAtRiskDescription = String(localized: "overview.streakAtRiskDescription")
        public static let removeLogEntry = String(localized: "overview.removeLogEntry")
        public static let remove = String(localized: "overview.remove")
        public static func removeLogMessage(_ habitName: String) -> String {
            String(format: String(localized: "overview.removeLogMessage"), habitName)
        }
        public static func todayDate(_ dateString: String) -> String {
            String(format: String(localized: "overview.todayDate"), dateString)
        }
        public static func nextHabit(_ habitName: String) -> String {
            String(format: String(localized: "overview.nextHabit"), habitName)
        }
        public static let remaining = String(localized: "overview.remaining")
        public static let completed = String(localized: "overview.completed")
        public static let analysisInProgress = String(localized: "overview.analysisInProgress")

        // Smart Insights Card
        public static let weeklyInsights = String(localized: "overview.weeklyInsights")
        public static let gatheringInsights = String(localized: "overview.gatheringInsights")
        public static let completeHabitsToUnlock = String(localized: "overview.completeHabitsToUnlock")

        // Streaks Card
        public static let currentStreaks = String(localized: "overview.currentStreaks")
        public static func streaksCount(_ count: Int) -> String {
            String(format: String(localized: "overview.streaksCount"), count, count == 1 ? "streak" : "streaks")
        }
        public static let loadingStreaks = String(localized: "overview.loadingStreaks")
        public static let noActiveStreaks = String(localized: "overview.noActiveStreaks")
        public static let startCompletingHabits = String(localized: "overview.startCompletingHabits")
    }
    
    // MARK: - Calendar
    public enum Calendar {
        public static let today = String(localized: "calendarToday")
    }
    
    // MARK: - Confirmation Dialogs
    public enum Dialog {
        public static let deleteHabit = String(localized: "dialogDeleteHabit")
        public static let deleteHabits = String(localized: "dialogDeleteHabits")
        public static let deactivateHabits = String(localized: "dialogDeactivateHabits")
        public static let cannotUndo = String(localized: "dialogCannotUndo")

        // Dynamic string with habit name interpolation
        public static func deleteHabitMessage(_ habitName: String) -> String {
            String(format: String(localized: "dialogDeleteHabitMessage"), habitName)
        }
        public static func deleteHabitConfirmation(_ habitName: String) -> String {
            String(format: String(localized: "dialogDeleteHabitConfirmation"), habitName)
        }
    }

    // MARK: - Habits Screen
    public enum Habits {
        // Empty states
        public static let noCategoryHabits = String(localized: "habits.noCategoryHabits")
        public static let noCategoryHabitsDescription = String(localized: "habits.noCategoryHabitsDescription")
        public static let noHabitsYet = String(localized: "habits.noHabitsYet")
        public static let tapToCreate = String(localized: "habits.tapToCreate")
        public static let tap = String(localized: "habits.tap")
        public static let or = String(localized: "habits.or")
        public static let toCreateFirstHabit = String(localized: "habits.toCreateFirstHabit")

        // Edit mode toolbar
        public static func selectedCount(_ count: Int) -> String {
            String(format: String(localized: "habits.selectedCount"), count)
        }
        public static let activate = String(localized: "habits.activate")
        public static let deactivate = String(localized: "habits.deactivate")

        // Accessibility
        public static let aiAssistant = String(localized: "habits.aiAssistant")
        public static let emptyStateAccessibility = String(localized: "habits.emptyStateAccessibility")

        // Reminders
        public static let sectionReminders = String(localized: "habits.sectionReminders")
        public static let noRemindersSet = String(localized: "habits.noRemindersSet")
        public static let addReminder = String(localized: "habits.addReminder")
        public static let reminderFooter = String(localized: "habits.reminderFooter")
        public static let add = String(localized: "habits.add")

        // Location
        public static let locationReminders = String(localized: "habits.locationReminders")
        public static func radiusMeters(_ radius: Int) -> String {
            String(format: String(localized: "habits.radiusMeters"), radius)
        }
        public static let locationBasedDescription = String(localized: "habits.locationBasedDescription")
        public static let locationBased = String(localized: "habits.locationBased")
        public static let locationAutoSkip = String(localized: "habits.locationAutoSkip")
        public static let locationPermissionDenied = String(localized: "habits.locationPermissionDenied")
        public static let meters = String(localized: "habits.meters")
        public static let detectionRadius = String(localized: "habits.detectionRadius")

        // Start Date
        public static let startDate = String(localized: "habits.startDate")
        public static let failedToLoadHistory = String(localized: "habits.failedToLoadHistory")
        public static let loadingHistory = String(localized: "habits.loadingHistory")
        public static let startDateAfterLogs = String(localized: "habits.startDateAfterLogs")
        public static let startDateFooter = String(localized: "habits.startDateFooter")

        // Category
        public static let sectionCategory = String(localized: "habits.sectionCategory")
        public static let loadingCategories = String(localized: "habits.loadingCategories")
        public static let loadingCategory = String(localized: "habits.loadingCategory")

        // Map
        public static let tapToViewMap = String(localized: "habits.tapToViewMap")
        public static let searchError = String(localized: "habits.searchError")

        // Form accessibility
        public static let habitName = String(localized: "habits.habitName")
        public static let habitType = String(localized: "habits.habitType")
        public static let unitLabel = String(localized: "habits.unitLabel")
        public static let dailyTarget = String(localized: "habits.dailyTarget")
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

        // TipKit In-App Tips
        public static let tapToLogTitle = String(localized: "tips.tapToLog.title")
        public static let tapToLogMessage = String(localized: "tips.tapToLog.message")
        public static let adjustCompletedTitle = String(localized: "tips.adjustCompleted.title")
        public static let adjustCompletedMessage = String(localized: "tips.adjustCompleted.message")
        public static let longPressTitle = String(localized: "tips.longPress.title")
        public static let longPressMessage = String(localized: "tips.longPress.message")
        public static let dailyProgressTitle = String(localized: "tips.dailyProgress.title")
        public static let dailyProgressMessage = String(localized: "tips.dailyProgress.message")
        public static let gotIt = String(localized: "tips.gotIt")
    }

    // MARK: - Timezone Change
    public enum TimezoneChange {
        public static let title = String(localized: "timezone.change.title")
        public static let keepHome = String(localized: "timezone.change.keepHome")
        public static let useCurrent = String(localized: "timezone.change.useCurrent")
        public static let movedHere = String(localized: "timezone.change.movedHere")
        public static func message(_ newTimezone: String) -> String {
            String(format: String(localized: "timezone.change.message"), newTimezone)
        }
    }

    // MARK: - Category Management
    public enum CategoryManagement {
        public static let category = String(localized: "category.category")
        public static let addCustom = String(localized: "category.addCustom")
        public static let createTitle = String(localized: "category.create.title")
        public static let createSubtitle = String(localized: "category.create.subtitle")
        public static let nameLabel = String(localized: "category.name.label")
        public static let namePlaceholder = String(localized: "category.name.placeholder")
        public static let chooseEmoji = String(localized: "category.chooseEmoji")
        public static let newCategory = String(localized: "category.new")
        public static let manageCategories = String(localized: "category.manage")
        public static let categories = String(localized: "category.categories")
        public static let manage = String(localized: "category.manageButton")
        public static let creatingCategory = String(localized: "category.creating")
        public static let failedToCreate = String(localized: "category.failedCreate")
        public static let loadingCategories = String(localized: "category.loading")
        public static let failedToLoad = String(localized: "category.failedLoad")
        public static let deleteCategories = String(localized: "category.delete.title")
        public static let deactivateCategories = String(localized: "category.deactivate.title")
        public static func selectedCount(_ count: Int) -> String {
            String(format: String(localized: "category.selectedCount"), count)
        }
        public static func deleteConfirmSingle(_ name: String) -> String {
            String(format: String(localized: "category.delete.confirmSingle"), name)
        }
        public static func deleteConfirmMultiple(_ count: Int) -> String {
            String(format: String(localized: "category.delete.confirmMultiple"), count)
        }
        public static func deactivateConfirmSingle(_ name: String) -> String {
            String(format: String(localized: "category.deactivate.confirmSingle"), name)
        }
        public static func deactivateConfirmMultiple(_ count: Int) -> String {
            String(format: String(localized: "category.deactivate.confirmMultiple"), count)
        }
    }

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
        public static func habitsCount(_ count: Int, _ max: Int) -> String {
            String(format: String(localized: "components.habitsCount"), count, max)
        }
        public static let viewHabitDetails = String(localized: "components.viewHabitDetails")

        // Habit Indicator Info Sheet
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

        // Category Filter
        public static let habitsAssistant = String(localized: "components.habitsAssistant")
        public static let assistantHint = String(localized: "components.assistantHint")
        public static let addHabit = String(localized: "components.addHabit")
        public static let createHabitHint = String(localized: "components.createHabitHint")
    }

    // MARK: - App Header
    public enum AppHeader {
        public static let profileLabel = String(localized: "appHeader.profile.label")
        public static let profileHint = String(localized: "appHeader.profile.hint")
        public static func progressLabel(_ appName: String) -> String {
            String(format: String(localized: "appHeader.progress.label"), appName)
        }
        public static func progressPercent(_ percent: Int) -> String {
            String(format: String(localized: "appHeader.progress.percent"), percent)
        }
    }

    // MARK: - Toast Notifications
    public enum Toast {
        public static let dismissLabel = String(localized: "toast.dismiss.label")
        public static let dismissHint = String(localized: "toast.dismiss.hint")
        public static let swipeHint = String(localized: "toast.swipe.hint")
    }

    // MARK: - Stats/Charts
    public enum Stats {
        // Chart Info Sheet
        public static let howItWorks = String(localized: "stats.howItWorks")
        public static let example = String(localized: "stats.example")
        public static let aboutThisChart = String(localized: "stats.aboutThisChart")

        // StatsView - Loading & Headers
        public static let loadingAnalytics = String(localized: "stats.loadingAnalytics")
        public static let progressTrend = String(localized: "stats.progressTrend")
        public static let aboutProgressTrend = String(localized: "stats.aboutProgressTrend")
        public static let progressTrendChart = String(localized: "stats.progressTrendChart")
        public static let habitPatterns = String(localized: "stats.habitPatterns")
        public static let understandConsistencyTrends = String(localized: "stats.understandConsistencyTrends")
        public static let aboutHabitPatterns = String(localized: "stats.aboutHabitPatterns")

        // Period Streaks
        public static let periodStreaks = String(localized: "stats.periodStreaks")
        public static let performanceDuringPeriod = String(localized: "stats.performanceDuringPeriod")
        public static let perfectDays = String(localized: "stats.perfectDays")
        public static let peak = String(localized: "stats.peak")
        public static let consistency = String(localized: "stats.consistency")
        public static func periodTrend(_ trend: String) -> String {
            String(format: String(localized: "stats.periodTrend"), trend)
        }

        // Category Performance
        public static let categoryPerformance = String(localized: "stats.categoryPerformance")
        public static let tapToViewCategoryHabits = String(localized: "stats.tapToViewCategoryHabits")
        public static func habitsCount(_ count: Int) -> String {
            String(format: String(localized: "stats.habitsCount"), count)
        }

        // Threshold Requirements
        public static let buildingYourProfile = String(localized: "stats.buildingYourProfile")
        public static let completeToUnlockInsights = String(localized: "stats.completeToUnlockInsights")

        // Performance Summary
        public static let excellentEveryDay = String(localized: "stats.excellentEveryDay")
        public static func consistentCompletion(_ percentage: Int) -> String {
            String(format: String(localized: "stats.consistentCompletion"), percentage)
        }
        public static let consistentAcrossDays = String(localized: "stats.consistentAcrossDays")
        public static func averageCompletion(_ percentage: Int) -> String {
            String(format: String(localized: "stats.averageCompletion"), percentage)
        }
        public static func dayWorksBest(_ day: String) -> String {
            String(format: String(localized: "stats.dayWorksBest"), day)
        }
        public static func completionRate(_ percentage: Int) -> String {
            String(format: String(localized: "stats.completionRate"), percentage)
        }

        // Optimization
        public static let considerRescheduling = String(localized: "stats.considerRescheduling")
        public static let noChangesNeeded = String(localized: "stats.noChangesNeeded")

        // Accessibility
        public static let weeklyPerformanceChart = String(localized: "stats.weeklyPerformanceChart")
        public static func excellentConsistentPerformance(_ percentage: Int) -> String {
            String(format: String(localized: "stats.excellentConsistentPerformance"), percentage)
        }
        public static func consistentPerformance(_ percentage: Int) -> String {
            String(format: String(localized: "stats.consistentPerformance"), percentage)
        }
        public static func bestDayPerformance(_ day: String, _ percentage: Int) -> String {
            String(format: String(localized: "stats.bestDayPerformance"), day, percentage)
        }

        // Progress Trend Info Sheet
        public static let progressTrendTitle = String(localized: "stats.progressTrendInfo.title")
        public static let progressTrendDescription = String(localized: "stats.progressTrendInfo.description")
        public static let progressTrendDetail1 = String(localized: "stats.progressTrendInfo.detail1")
        public static let progressTrendDetail2 = String(localized: "stats.progressTrendInfo.detail2")
        public static let progressTrendDetail3 = String(localized: "stats.progressTrendInfo.detail3")
        public static let progressTrendExample = String(localized: "stats.progressTrendInfo.example")

        // Habit Patterns Info Sheet
        public static let habitPatternsTitle = String(localized: "stats.habitPatternsInfo.title")
        public static let habitPatternsDescription = String(localized: "stats.habitPatternsInfo.description")
        public static let habitPatternsDetail1 = String(localized: "stats.habitPatternsInfo.detail1")
        public static let habitPatternsDetail2 = String(localized: "stats.habitPatternsInfo.detail2")
        public static let habitPatternsDetail3 = String(localized: "stats.habitPatternsInfo.detail3")
        public static let habitPatternsExample = String(localized: "stats.habitPatternsInfo.example")
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
        public static let title = String(localized: "paywall.title")
        public static let loadingPlans = String(localized: "paywall.loadingPlans")
        public static let loadingPro = String(localized: "paywall.loadingPro")
        public static let unableToLoad = String(localized: "paywall.unableToLoad")
        public static let unableToLoadMessage = String(localized: "paywall.unableToLoadMessage")

        // Header
        public static let headerTitle = String(localized: "paywall.header.title")
        public static let headerSubtitle = String(localized: "paywall.header.subtitle")

        // Sections
        public static let whatsIncluded = String(localized: "paywall.whatsIncluded")
        public static let choosePlan = String(localized: "paywall.choosePlan")
        public static let popular = String(localized: "paywall.popular")

        // Offer Code
        public static let havePromoCode = String(localized: "paywall.havePromoCode")
        public static let redeemOfferCode = String(localized: "paywall.redeemOfferCode")

        // Purchase
        public static let processing = String(localized: "paywall.processing")
        public static let purchase = String(localized: "paywall.purchase")
        public static let startFreeTrial = String(localized: "paywall.startFreeTrial")
        public static let selectPlan = String(localized: "paywall.selectPlan")
        public static let productsError = String(localized: "paywall.productsError")
        public static let restorePurchases = String(localized: "paywall.restorePurchases")

        // Dynamic
        public static func trialInfo(_ price: String) -> String {
            String(format: String(localized: "paywall.trialInfo"), price)
        }

        // Legal
        public static let subscriptionTerms = String(localized: "paywall.subscriptionTerms")

        // Discount badges
        public static func discountSavePercent(_ percent: Int) -> String {
            String(format: String(localized: "paywall.discount.savePercent"), percent)
        }
    }

    // MARK: - Personality Insights
    public enum PersonalityInsights {
        public static let title = String(localized: "personality.title")
        public static let settingsTitle = String(localized: "personality.settings.title")
        public static let analysisFrequency = String(localized: "personality.analysisFrequency")
        public static let aboutBigFive = String(localized: "personality.aboutBigFive")
        public static let tapToViewInsights = String(localized: "personality.tapToViewInsights")
        public static let personalityAnalysis = String(localized: "personality.analysis")
    }

    // MARK: - Habit Status
    public enum HabitStatus {
        public static let title = String(localized: "habitStatus.title")
    }

    // MARK: - Onboarding Flow
    public enum Onboarding {
        // Page Titles (for VoiceOver)
        public static let pageWelcome = String(localized: "onboarding.page.welcome")
        public static let pageTrackHabits = String(localized: "onboarding.page.trackHabits")
        public static let pageMakeItYours = String(localized: "onboarding.page.makeItYours")
        public static let pageLearnImprove = String(localized: "onboarding.page.learnImprove")
        public static let pageFreePro = String(localized: "onboarding.page.freePro")
        public static let pagePermissions = String(localized: "onboarding.page.permissions")

        // Accessibility
        public static func stepAnnouncement(_ step: Int, _ total: Int, _ title: String) -> String {
            String(format: String(localized: "onboarding.stepAnnouncement"), step, total, title)
        }
        public static func pageAnnouncement(_ step: Int) -> String {
            String(format: String(localized: "onboarding.pageAnnouncement"), step)
        }
        public static func progressLabel(_ step: Int, _ total: Int) -> String {
            String(format: String(localized: "onboarding.progressLabel"), step, total)
        }
        public static func progressPercent(_ percent: Int) -> String {
            String(format: String(localized: "onboarding.progressPercent"), percent)
        }

        // Navigation Buttons
        public static let skip = String(localized: "onboarding.skip")
        public static let skipHint = String(localized: "onboarding.skipHint")
        public static let back = String(localized: "onboarding.back")
        public static let backHint = String(localized: "onboarding.backHint")
        public static let getStarted = String(localized: "onboarding.getStarted")
        public static let continueButton = String(localized: "onboarding.continue")
        public static let completeHint = String(localized: "onboarding.completeHint")
        public static let nextHint = String(localized: "onboarding.nextHint")

        // Page 1 - Welcome
        public static let welcomeTitle = String(localized: "onboarding.page1.title")
        public static let welcomeSubtitle = String(localized: "onboarding.page1.subtitle")
        public static let namePlaceholder = String(localized: "onboarding.page1.namePlaceholder")
        public static let genderPlaceholder = String(localized: "onboarding.page1.genderPlaceholder")
        public static let agePlaceholder = String(localized: "onboarding.page1.agePlaceholder")
        public static func nameHint(_ maxLength: Int) -> String {
            String(format: String(localized: "onboarding.page1.nameHint"), maxLength)
        }

        // Page 2 - Track Habits
        public static let trackHabitsTitle = String(localized: "onboarding.page2.title")
        public static let trackHabitsSubtitle = String(localized: "onboarding.page2.subtitle")
        public static func trackHabitsGreeting(_ name: String) -> String {
            String(format: String(localized: "onboarding.page2.greeting"), name)
        }
        public static let dailyTrackingTitle = String(localized: "onboarding.page2.dailyTracking.title")
        public static let dailyTrackingDescription = String(localized: "onboarding.page2.dailyTracking.description")
        public static let progressVisualizationTitle = String(localized: "onboarding.page2.progressVisualization.title")
        public static let progressVisualizationDescription = String(localized: "onboarding.page2.progressVisualization.description")
        public static let smartRemindersTitle = String(localized: "onboarding.page2.smartReminders.title")
        public static let smartRemindersDescription = String(localized: "onboarding.page2.smartReminders.description")
        public static let iCloudSyncTitle = String(localized: "onboarding.page2.iCloudSync.title")
        public static let iCloudSyncDescription = String(localized: "onboarding.page2.iCloudSync.description")

        // Page 3 - Make It Yours
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

        // Page 4 - Learn & Improve
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

        // Page 6 - Permissions
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

        // App Launch
        public static let preparingExperience = String(localized: "onboarding.appLaunch.preparingExperience")
        public static let onlyTakesMoment = String(localized: "onboarding.appLaunch.onlyTakesMoment")
        public static let loading = String(localized: "onboarding.appLaunch.loading")
        public static let loadingAccessibility = String(localized: "onboarding.appLaunch.loadingAccessibility")
        public static let preparingAccessibility = String(localized: "onboarding.appLaunch.preparingAccessibility")

        // Welcome Back (returning user)
        public static let welcomeBackWithName = String(localized: "onboarding.welcomeBack.withName")
        public static let welcomeBackWithoutName = String(localized: "onboarding.welcomeBack.withoutName")
        public static let dataSyncedFromICloud = String(localized: "onboarding.welcomeBack.dataSynced")
        public static func habitsSynced(_ count: Int) -> String {
            String(format: String(localized: "onboarding.welcomeBack.habitsSynced"), count)
        }
        public static func categoriesSynced(_ count: Int) -> String {
            String(format: String(localized: "onboarding.welcomeBack.categoriesSynced"), count)
        }
        public static let profileRestored = String(localized: "onboarding.welcomeBack.profileRestored")
        public static let letsSetUpDevice = String(localized: "onboarding.welcomeBack.letsSetUpDevice")
        public static let continueToSetUp = String(localized: "onboarding.welcomeBack.continueToSetUp")

        // Returning User Steps
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

    // MARK: - Habits Assistant
    public enum HabitsAssistant {
        public static let firstVisitTitle = String(localized: "habits_assistant.first_visit.title")
        public static let firstVisitDescription = String(localized: "habits_assistant.first_visit.description")
        public static let title = String(localized: "habitsAssistant.title")
        public static let accessibilityLabel = String(localized: "habitsAssistant.accessibilityLabel")
        public static let accessibilityHint = String(localized: "habitsAssistant.accessibilityHint")
        public static let addHabitLabel = String(localized: "habitsAssistant.addHabit.label")
        public static let addHabitHint = String(localized: "habitsAssistant.addHabit.hint")
    }

    // MARK: - Location
    public enum Location {
        // Map Location Picker
        public static let selectLocation = String(localized: "location.select_location")
        public static let searchPlaceholder = String(localized: "location.search_placeholder")
        public static let tapOnMap = String(localized: "location.tap_on_map")
        public static let tapToViewMap = String(localized: "location.tap_to_view_map")
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

        // Section
        public static let sectionSync = String(localized: "icloud.sectionSync")
        public static let iCloud = String(localized: "icloud.iCloud")
        public static let syncingAcrossDevices = String(localized: "icloud.syncingAcrossDevices")
        public static let tapToEnableSync = String(localized: "icloud.tapToEnableSync")

        // Settings View
        public static let title = String(localized: "icloud.title")
        public static let description = String(localized: "icloud.description")
        public static let syncStatus = String(localized: "icloud.syncStatus")
        public static let syncStatusFooter = String(localized: "icloud.syncStatusFooter")
        public static let whatSyncs = String(localized: "icloud.whatSyncs")
        public static let whatSyncsFooter = String(localized: "icloud.whatSyncsFooter")
        public static let troubleshooting = String(localized: "icloud.troubleshooting")
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

        // Section header
        public static let sectionDataManagement = String(localized: "data_management.section")

        // Export/Import
        public static let exporting = String(localized: "data_management.exporting")
        public static let export = String(localized: "data_management.export")
        public static let importing = String(localized: "data_management.importing")
        public static let importData = String(localized: "data_management.import")
        public static let deleting = String(localized: "data_management.deleting")
        public static let exportSuccess = String(localized: "data_management.export_success")
        public static func exportFailed(_ error: String) -> String {
            String(format: String(localized: "data_management.export_failed"), error)
        }
        public static func importFailed(_ error: String) -> String {
            String(format: String(localized: "data_management.import_failed"), error)
        }
        public static let unableToAccessFile = String(localized: "data_management.unable_to_access_file")
        public static let invalidFile = String(localized: "data_management.invalid_file")
    }

    // MARK: - Subscription
    public enum Subscription {
        public static let sectionHeader = String(localized: "subscription.section")
        public static let mode = String(localized: "subscription.mode")
        public static let allFeaturesUnlocked = String(localized: "subscription.all_features_unlocked")
        public static let renews = String(localized: "subscription.renews")
        public static let billingStarts = String(localized: "subscription.billing_starts")
        public static let trial = String(localized: "subscription.trial")
        public static let trialEndsOn = String(localized: "subscription.trial_ends_on")
        public static let restoring = String(localized: "subscription.restoring")
        public static let restorePurchases = String(localized: "subscription.restore_purchases")
        public static let manageSubscription = String(localized: "subscription.manage_subscription")

        // Restore alerts
        public static func restoredPurchases(_ count: Int) -> String {
            String(format: String(localized: "subscription.restored_purchases"), count)
        }
        public static let noPurchasesToRestore = String(localized: "subscription.no_purchases_to_restore")
        public static let restoreFailed = String(localized: "subscription.restore_failed")

        // Footer texts
        public static let allFeaturesFooter = String(localized: "subscription.all_features_footer")
        public static let freeFooter = String(localized: "subscription.free_footer")
        public static let weeklyFooter = String(localized: "subscription.weekly_footer")
        public static let monthlyFooter = String(localized: "subscription.monthly_footer")
        public static let annualFooter = String(localized: "subscription.annual_footer")
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
        public static let close = String(localized: "common.close")
        public static let ok = String(localized: "common.ok")
        public static let error = String(localized: "common.error")
        public static let add = String(localized: "common.add")
        public static let delete = String(localized: "common.delete")
        public static let decrease = String(localized: "common.decrease")
        public static let increase = String(localized: "common.increase")
        public static let save = String(localized: "common.save")
        public static let settings = String(localized: "common.settings")
        public static let remove = String(localized: "common.remove")
        public static let deactivate = String(localized: "common.deactivate")
        public static let tryAgain = String(localized: "common.tryAgain")
        public static let clearAll = String(localized: "common.clearAll")
        public static let restore = String(localized: "common.restore")
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
