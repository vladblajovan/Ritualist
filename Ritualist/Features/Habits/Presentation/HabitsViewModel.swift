import Foundation
import Observation

@MainActor @Observable
public final class HabitsViewModel {
    private let getAllHabits: GetAllHabitsUseCase
    private let createHabit: CreateHabitUseCase
    private let updateHabit: UpdateHabitUseCase
    private let deleteHabit: DeleteHabitUseCase
    
    public private(set) var items: [Habit] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var isCreating = false
    public private(set) var isUpdating = false
    public private(set) var isDeleting = false
    
    public init(getAllHabits: GetAllHabitsUseCase, 
                createHabit: CreateHabitUseCase,
                updateHabit: UpdateHabitUseCase,
                deleteHabit: DeleteHabitUseCase) {
        self.getAllHabits = getAllHabits
        self.createHabit = createHabit
        self.updateHabit = updateHabit
        self.deleteHabit = deleteHabit
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        do { 
            items = try await getAllHabits.execute() 
        } catch { 
            self.error = error
            items = [] 
        }
        
        isLoading = false
    }
    
    public func create(_ habit: Habit) async -> Bool {
        isCreating = true
        error = nil
        
        do {
            try await createHabit.execute(habit)
            await load() // Refresh the list
            isCreating = false
            return true
        } catch {
            self.error = error
            isCreating = false
            return false
        }
    }
    
    public func update(_ habit: Habit) async -> Bool {
        isUpdating = true
        error = nil
        
        do {
            try await updateHabit.execute(habit)
            await load() // Refresh the list
            isUpdating = false
            return true
        } catch {
            self.error = error
            isUpdating = false
            return false
        }
    }
    
    public func delete(id: UUID) async -> Bool {
        isDeleting = true
        error = nil
        
        do {
            try await deleteHabit.execute(id: id)
            await load() // Refresh the list
            isDeleting = false
            return true
        } catch {
            self.error = error
            isDeleting = false
            return false
        }
    }
    
    public func retry() async {
        await load()
    }
}
