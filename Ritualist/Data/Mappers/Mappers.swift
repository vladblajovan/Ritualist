import Foundation

public enum HabitMapper {
    public static func toSD(_ habit: Habit) throws -> SDHabit {
        let schedule = try JSONEncoder().encode(habit.schedule)
        let reminders = try JSONEncoder().encode(habit.reminders)
        let kindRaw = (habit.kind == .binary) ? 0 : 1
        return SDHabit(id: habit.id, name: habit.name, colorHex: habit.colorHex, emoji: habit.emoji,
                       kindRaw: kindRaw, unitLabel: habit.unitLabel, dailyTarget: habit.dailyTarget,
                       scheduleData: schedule, remindersData: reminders, startDate: habit.startDate,
                       endDate: habit.endDate, isActive: habit.isActive, displayOrder: habit.displayOrder,
                       categoryId: habit.categoryId, suggestionId: habit.suggestionId)
    }
    public static func fromSD(_ sd: SDHabit) throws -> Habit {
        let schedule = try JSONDecoder().decode(HabitSchedule.self, from: sd.scheduleData)
        let reminders = try JSONDecoder().decode([ReminderTime].self, from: sd.remindersData)
        let kind: HabitKind = (sd.kindRaw == 0) ? .binary : .numeric
        return Habit(id: sd.id, name: sd.name, colorHex: sd.colorHex, emoji: sd.emoji, kind: kind,
                     unitLabel: sd.unitLabel, dailyTarget: sd.dailyTarget, schedule: schedule,
                     reminders: reminders, startDate: sd.startDate, endDate: sd.endDate, isActive: sd.isActive,
                     displayOrder: sd.displayOrder, categoryId: sd.categoryId, suggestionId: sd.suggestionId)
    }
}

public enum HabitLogMapper {
    public static func toSD(_ log: HabitLog) -> SDHabitLog {
        SDHabitLog(id: log.id, habitID: log.habitID, date: log.date, value: log.value)
    }
    public static func fromSD(_ sd: SDHabitLog) -> HabitLog {
        HabitLog(id: sd.id, habitID: sd.habitID, date: sd.date, value: sd.value)
    }
}

public enum ProfileMapper {
    public static func toSD(_ profile: UserProfile) -> SDUserProfile {
        SDUserProfile(id: profile.id, 
                      name: profile.name, 
                      avatarImageData: profile.avatarImageData,
                      appearance: profile.appearance,
                      subscriptionPlan: profile.subscriptionPlan.rawValue,
                      subscriptionExpiryDate: profile.subscriptionExpiryDate,
                      createdAt: profile.createdAt,
                      updatedAt: profile.updatedAt)
    }
    
    public static func fromSD(_ sd: SDUserProfile) -> UserProfile {
        let subscriptionPlan = SubscriptionPlan(rawValue: sd.subscriptionPlan) ?? .free
        return UserProfile(id: sd.id, 
                          name: sd.name, 
                          avatarImageData: sd.avatarImageData,
                          appearance: sd.appearance,
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
            isActive: category.isActive
        )
    }
    
    public static func fromSD(_ sd: SDCategory) -> Category {
        Category(
            id: sd.id,
            name: sd.name,
            displayName: sd.displayName,
            emoji: sd.emoji,
            order: sd.order,
            isActive: sd.isActive
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
