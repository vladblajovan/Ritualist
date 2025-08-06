import Foundation
import FactoryKit

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
    
    var getHabitCount: Factory<GetHabitCount> {
        self { GetHabitCount(habitRepository: self.habitRepository()) }
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
    
    // MARK: - Complex Habit Operations
    
    @MainActor
    var createHabitFromSuggestionUseCase: Factory<CreateHabitFromSuggestionUseCase> {
        self { @MainActor in
            CreateHabitFromSuggestion(
                createHabit: self.createHabit(),
                getHabitCount: self.getHabitCount(),
                checkHabitCreationLimit: self.checkHabitCreationLimit(),
                featureGatingService: self.featureGatingService()
            )
        }
    }
}