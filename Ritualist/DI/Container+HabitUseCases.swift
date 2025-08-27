import Foundation
import FactoryKit
import RitualistCore

// MARK: - Habit Use Cases Container Extensions

extension Container {
    
    // MARK: - Basic Habit Operations
    
    var createHabit: Factory<CreateHabit> {
        self { CreateHabit(repo: self.habitRepository()) }
    }
    
    var updateHabit: Factory<UpdateHabit> {
        self { UpdateHabit(repo: self.habitRepository()) }
    }
    
    var deleteHabit: Factory<DeleteHabit> {
        self { DeleteHabit(repo: self.habitRepository()) }
    }
    
    var getAllHabits: Factory<GetAllHabits> {
        self { GetAllHabits(repo: self.habitRepository()) }
    }
    
    var loadHabitsData: Factory<LoadHabitsData> {
        self { LoadHabitsData(habitRepo: self.habitRepository(), categoryRepo: self.categoryRepository()) }
    }
    
    var getHabitCount: Factory<GetHabitCount> {
        self { GetHabitCount(repo: self.habitRepository()) }
    }
    
    // MARK: - Habit Management Operations
    
    var toggleHabitActiveStatus: Factory<ToggleHabitActiveStatus> {
        self { ToggleHabitActiveStatus(repo: self.habitRepository()) }
    }
    
    var reorderHabits: Factory<ReorderHabits> {
        self { ReorderHabits(repo: self.habitRepository()) }
    }
    
    var validateHabitUniqueness: Factory<ValidateHabitUniqueness> {
        self { ValidateHabitUniqueness(repo: self.habitRepository()) }
    }
    
    var cleanupOrphanedHabits: Factory<CleanupOrphanedHabits> {
        self { CleanupOrphanedHabits(repo: self.habitRepository()) }
    }
    
    // MARK: - Complex Habit Operations
    
    var createHabitFromSuggestionUseCase: Factory<CreateHabitFromSuggestionUseCase> {
        self {
            CreateHabitFromSuggestion(
                createHabit: self.createHabit(),
                getHabitCount: self.getHabitCount(),
                checkHabitCreationLimit: self.checkHabitCreationLimit(),
                featureGatingService: self.featureGatingService()
            )
        }
    }
    
    var removeHabitFromSuggestionUseCase: Factory<RemoveHabitFromSuggestionUseCase> {
        self {
            RemoveHabitFromSuggestion(
                deleteHabit: self.deleteHabit()
            )
        }
    }
    
    // MARK: - Habit Calculation Operations
    
    var isHabitCompleted: Factory<IsHabitCompleted> {
        self { IsHabitCompleted(habitCompletionService: self.habitCompletionService()) }
    }
    
    var calculateDailyProgress: Factory<CalculateDailyProgress> {
        self { CalculateDailyProgress(habitCompletionService: self.habitCompletionService()) }
    }
    
    var isScheduledDay: Factory<IsScheduledDay> {
        self { IsScheduledDay(habitCompletionService: self.habitCompletionService()) }
    }
}