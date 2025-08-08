import Foundation
import SwiftData

public enum HabitMapper {
    public static func toSD(_ habit: Habit, context: ModelContext? = nil) throws -> SDHabit {
        let schedule = try JSONEncoder().encode(habit.schedule)
        let reminders = try JSONEncoder().encode(habit.reminders)
        let kindRaw = (habit.kind == .binary) ? 0 : 1
        
        // Find the category if categoryId is provided
        var category: SDCategory?
        if let categoryId = habit.categoryId, let context = context {
            let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == categoryId })
            category = try context.fetch(descriptor).first
        }
        
        return SDHabit(id: habit.id, name: habit.name, colorHex: habit.colorHex, emoji: habit.emoji,
                       kindRaw: kindRaw, unitLabel: habit.unitLabel, dailyTarget: habit.dailyTarget,
                       scheduleData: schedule, remindersData: reminders, startDate: habit.startDate,
                       endDate: habit.endDate, isActive: habit.isActive, displayOrder: habit.displayOrder,
                       category: category, suggestionId: habit.suggestionId)
    }
    public static func fromSD(_ sd: SDHabit) throws -> Habit {
        let schedule = try JSONDecoder().decode(HabitSchedule.self, from: sd.scheduleData)
        let reminders = try JSONDecoder().decode([ReminderTime].self, from: sd.remindersData)
        let kind: HabitKind = (sd.kindRaw == 0) ? .binary : .numeric
        let categoryId = sd.category?.id // Extract categoryId from relationship
        return Habit(id: sd.id, name: sd.name, colorHex: sd.colorHex, emoji: sd.emoji, kind: kind,
                     unitLabel: sd.unitLabel, dailyTarget: sd.dailyTarget, schedule: schedule,
                     reminders: reminders, startDate: sd.startDate, endDate: sd.endDate, isActive: sd.isActive,
                     displayOrder: sd.displayOrder, categoryId: categoryId, suggestionId: sd.suggestionId)
    }
}

public enum HabitLogMapper {
    public static func toSD(_ log: HabitLog, context: ModelContext? = nil) -> SDHabitLog {
        // Find the habit if habitID is provided and context is available
        var habit: SDHabit?
        if let context = context {
            let descriptor = FetchDescriptor<SDHabit>(predicate: #Predicate { $0.id == log.habitID })
            habit = try? context.fetch(descriptor).first
        }
        return SDHabitLog(id: log.id, habit: habit, date: log.date, value: log.value)
    }
    public static func fromSD(_ sd: SDHabitLog) -> HabitLog {
        let habitID = sd.habit?.id ?? UUID() // Fallback to empty UUID if relationship is nil
        return HabitLog(id: sd.id, habitID: habitID, date: sd.date, value: sd.value)
    }
}

public enum ProfileMapper {
    public static func toSD(_ profile: UserProfile) -> SDUserProfile {
        SDUserProfile(id: profile.id.uuidString, 
                      name: profile.name, 
                      avatarImageData: profile.avatarImageData,
                      appearance: String(profile.appearance),
                      subscriptionPlan: profile.subscriptionPlan.rawValue,
                      subscriptionExpiryDate: profile.subscriptionExpiryDate,
                      createdAt: profile.createdAt,
                      updatedAt: profile.updatedAt)
    }
    
    public static func fromSD(_ sd: SDUserProfile) -> UserProfile {
        let subscriptionPlan = SubscriptionPlan(rawValue: sd.subscriptionPlan) ?? .free
        let id = UUID(uuidString: sd.id) ?? UUID()
        let appearance = Int(sd.appearance) ?? 0
        return UserProfile(id: id, 
                          name: sd.name, 
                          avatarImageData: sd.avatarImageData,
                          appearance: appearance,
                          subscriptionPlan: subscriptionPlan,
                          subscriptionExpiryDate: sd.subscriptionExpiryDate,
                          createdAt: sd.createdAt,
                          updatedAt: sd.updatedAt)
    }
}

public enum CategoryMapper {
    public static func toSD(_ category: Category) -> SDCategory {
        SDCategory(
            id: category.id,
            name: category.name,
            displayName: category.displayName,
            emoji: category.emoji,
            order: category.order,
            isActive: category.isActive,
            isPredefined: category.isPredefined
        )
    }
    
    public static func fromSD(_ sd: SDCategory) -> Category {
        Category(
            id: sd.id,
            name: sd.name,
            displayName: sd.displayName,
            emoji: sd.emoji,
            order: sd.order,
            isActive: sd.isActive,
            isPredefined: sd.isPredefined
        )
    }
}

public enum OnboardingMapper {
    public static func toSD(_ state: OnboardingState) -> SDOnboardingState {
        SDOnboardingState(isCompleted: state.isCompleted, completedDate: state.completedDate,
                         userName: state.userName, hasGrantedNotifications: state.hasGrantedNotifications)
    }
    public static func fromSD(_ sd: SDOnboardingState) -> OnboardingState {
        OnboardingState(isCompleted: sd.isCompleted, completedDate: sd.completedDate,
                       userName: sd.userName, hasGrantedNotifications: sd.hasGrantedNotifications)
    }
}
