import Foundation

// MARK: - Habits Strings

extension Strings {
    // MARK: - Habits Screen
    public enum Habits {
        public static let noCategoryHabits = String(localized: "habits.noCategoryHabits")
        public static let noCategoryHabitsDescription = String(localized: "habits.noCategoryHabitsDescription")
        public static let noHabitsYet = String(localized: "habits.noHabitsYet")
        public static let tapToCreate = String(localized: "habits.tapToCreate")
        public static let tap = String(localized: "habits.tap")
        public static let or = String(localized: "habits.or")
        public static let toCreateFirstHabit = String(localized: "habits.toCreateFirstHabit")
        public static func selectedCount(_ count: Int) -> String { String(format: String(localized: "habits.selectedCount"), count) }
        public static let activate = String(localized: "habits.activate")
        public static let deactivate = String(localized: "habits.deactivate")
        public static let aiAssistant = String(localized: "habits.aiAssistant")
        public static let emptyStateAccessibility = String(localized: "habits.emptyStateAccessibility")
        public static let sectionReminders = String(localized: "habits.sectionReminders")
        public static let noRemindersSet = String(localized: "habits.noRemindersSet")
        public static let addReminder = String(localized: "habits.addReminder")
        public static let reminderFooter = String(localized: "habits.reminderFooter")
        public static let add = String(localized: "habits.add")
        public static let locationReminders = String(localized: "habits.locationReminders")
        public static func radiusMeters(_ radius: Int) -> String { String(format: String(localized: "habits.radiusMeters"), radius) }
        public static let locationBasedDescription = String(localized: "habits.locationBasedDescription")
        public static let locationBased = String(localized: "habits.locationBased")
        public static let locationAutoSkip = String(localized: "habits.locationAutoSkip")
        public static let locationPermissionDenied = String(localized: "habits.locationPermissionDenied")
        public static let meters = String(localized: "habits.meters")
        public static let detectionRadius = String(localized: "habits.detectionRadius")
        public static let startDate = String(localized: "habits.startDate")
        public static let failedToLoadHistory = String(localized: "habits.failedToLoadHistory")
        public static let loadingHistory = String(localized: "habits.loadingHistory")
        public static let startDateAfterLogs = String(localized: "habits.startDateAfterLogs")
        public static let startDateFooter = String(localized: "habits.startDateFooter")
        public static let sectionCategory = String(localized: "habits.sectionCategory")
        public static let loadingCategories = String(localized: "habits.loadingCategories")
        public static let loadingCategory = String(localized: "habits.loadingCategory")
        public static let tapToViewMap = String(localized: "habits.tapToViewMap")
        public static let searchError = String(localized: "habits.searchError")
        public static let habitName = String(localized: "habits.habitName")
        public static let habitType = String(localized: "habits.habitType")
        public static let unitLabel = String(localized: "habits.unitLabel")
        public static let dailyTarget = String(localized: "habits.dailyTarget")
    }

    // MARK: - Habit Status
    public enum HabitStatus {
        public static let title = String(localized: "habitStatus.title")
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
        public static func selectedCount(_ count: Int) -> String { String(format: String(localized: "category.selectedCount"), count) }
        public static func deleteConfirmSingle(_ name: String) -> String { String(format: String(localized: "category.delete.confirmSingle"), name) }
        public static func deleteConfirmMultiple(_ count: Int) -> String { String(format: String(localized: "category.delete.confirmMultiple"), count) }
        public static func deactivateConfirmSingle(_ name: String) -> String { String(format: String(localized: "category.deactivate.confirmSingle"), name) }
        public static func deactivateConfirmMultiple(_ count: Int) -> String { String(format: String(localized: "category.deactivate.confirmMultiple"), count) }
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
        public static let searchPlaceholder = String(localized: "habitsAssistant.searchPlaceholder")
        public static let noSearchResults = String(localized: "habitsAssistant.noSearchResults")
        public static let tryDifferentKeywords = String(localized: "habitsAssistant.tryDifferentKeywords")
    }
}
