import Foundation
import Observation
import Combine

@MainActor @Observable
public final class HabitsViewModel {
    private let getAllHabits: GetAllHabitsUseCase
    private let createHabit: CreateHabitUseCase
    private let updateHabit: UpdateHabitUseCase
    private let deleteHabit: DeleteHabitUseCase
    private let toggleHabitActiveStatus: ToggleHabitActiveStatusUseCase
    private let refreshTrigger: RefreshTrigger
    
    // Reactive coordination
    private var cancellables = Set<AnyCancellable>()
    
    public private(set) var items: [Habit] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var isCreating = false
    public private(set) var isUpdating = false
    public private(set) var isDeleting = false
    
    public init(getAllHabits: GetAllHabitsUseCase, 
                createHabit: CreateHabitUseCase,
                updateHabit: UpdateHabitUseCase,
                deleteHabit: DeleteHabitUseCase,
                toggleHabitActiveStatus: ToggleHabitActiveStatusUseCase,
                refreshTrigger: RefreshTrigger) {
        self.getAllHabits = getAllHabits
        self.createHabit = createHabit
        self.updateHabit = updateHabit
        self.deleteHabit = deleteHabit
        self.toggleHabitActiveStatus = toggleHabitActiveStatus
        self.refreshTrigger = refreshTrigger
        
        setupRefreshObservation()
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
            refreshTrigger.triggerHabitCountRefresh()
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
            refreshTrigger.triggerHabitCountRefresh()
            isDeleting = false
            return true
        } catch {
            self.error = error
            isDeleting = false
            return false
        }
    }
    
    public func toggleActiveStatus(id: UUID) async -> Bool {
        isUpdating = true
        error = nil
        
        do {
            _ = try await toggleHabitActiveStatus.execute(id: id)
            await load() // Refresh the list
            isUpdating = false
            return true
        } catch {
            self.error = error
            isUpdating = false
            return false
        }
    }
    
    public func retry() async {
        await load()
    }
    
    private func setupRefreshObservation() {
        // React to habit count refresh triggers
        refreshTrigger.$habitCountNeedsRefresh
            .sink { [weak self] needsRefresh in
                if needsRefresh {
                    Task { [weak self] in
                        await self?.load()
                        await MainActor.run {
                            self?.refreshTrigger.resetHabitCountRefresh()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}
