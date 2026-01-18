import Foundation
import SwiftUI

/// Centralized localized strings for the app.
/// Split across multiple files using extensions for maintainability.
public struct Strings {
    private init() {}

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
        public static let mon = String(localized: "dayMon")
        public static let tue = String(localized: "dayTue")
        public static let wed = String(localized: "dayWed")
        public static let thu = String(localized: "dayThu")
        public static let fri = String(localized: "dayFri")
        public static let sat = String(localized: "daySat")
        public static let sun = String(localized: "daySun")
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
        public static func deleteHabitMessage(_ habitName: String) -> String { String(format: String(localized: "dialogDeleteHabitMessage"), habitName) }
        public static func deleteHabitConfirmation(_ habitName: String) -> String { String(format: String(localized: "dialogDeleteHabitConfirmation"), habitName) }
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
}

// MARK: - SwiftUI Extensions

extension Text {
    public init(localizedKey key: LocalizedStringKey) { self.init(key) }
}

// MARK: - Localization Helpers

extension String {
    public init(localized key: String, defaultValue: String = "") {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            self.init(localized: String.LocalizationValue(key))
        } else {
            self = NSLocalizedString(key, comment: "")
        }
    }
}
