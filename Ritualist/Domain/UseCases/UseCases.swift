import Foundation

// MARK: - Habit Use Cases
public protocol CreateHabitUseCase { func execute(_ habit: Habit) async throws }
public protocol GetActiveHabitsUseCase { func execute() async throws -> [Habit] }
public protocol GetAllHabitsUseCase { func execute() async throws -> [Habit] }
public protocol UpdateHabitUseCase { func execute(_ habit: Habit) async throws }
public protocol DeleteHabitUseCase { func execute(id: UUID) async throws }

// MARK: - Log Use Cases
public protocol GetLogsUseCase { func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] }
public protocol LogHabitUseCase { func execute(_ log: HabitLog) async throws }
public protocol DeleteLogUseCase { func execute(id: UUID) async throws }
public protocol GetLogForDateUseCase { func execute(habitID: UUID, date: Date) async throws -> HabitLog? }

// MARK: - Profile Use Cases  
public protocol LoadProfileUseCase { func execute() async throws -> UserProfile }
public protocol SaveProfileUseCase { func execute(_ profile: UserProfile) async throws }

// MARK: - Tip Use Cases
public protocol GetAllTipsUseCase { func execute() async throws -> [Tip] }
public protocol GetFeaturedTipsUseCase { func execute() async throws -> [Tip] }
public protocol GetTipByIdUseCase { func execute(id: UUID) async throws -> Tip? }
public protocol GetTipsByCategoryUseCase { func execute(category: TipCategory) async throws -> [Tip] }

// MARK: - Onboarding Use Cases
public protocol GetOnboardingStateUseCase { func execute() async throws -> OnboardingState }
public protocol SaveOnboardingStateUseCase { func execute(_ state: OnboardingState) async throws }
public protocol CompleteOnboardingUseCase { func execute(userName: String?, hasNotifications: Bool) async throws }

// MARK: - Habit Use Case Implementations
public final class CreateHabit: CreateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws { try await repo.create(habit) }
}

public final class GetActiveHabits: GetActiveHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> [Habit] {
        // Business logic: Filter only active habits
        let allHabits = try await repo.fetchAllHabits()
        return allHabits.filter { $0.isActive }
    }
}

public final class GetAllHabits: GetAllHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> [Habit] { try await repo.fetchAllHabits() }
}

public final class UpdateHabit: UpdateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws { try await repo.update(habit) }
}

public final class DeleteHabit: DeleteHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(id: UUID) async throws { try await repo.delete(id: id) }
}

// MARK: - Profile Use Case Implementations
public final class LoadProfile: LoadProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute() async throws -> UserProfile { try await repo.loadProfile() }
}

public final class SaveProfile: SaveProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute(_ profile: UserProfile) async throws { try await repo.saveProfile(profile) }
}

// MARK: - Log Use Case Implementations
public final class GetLogs: GetLogsUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] {
        // Get all logs from repository (no filtering in repository layer)
        let allLogs = try await repo.logs(for: habitID)

        // Business logic: Filter by date range
        return allLogs.filter { log in
            if let since, log.date < since { return false }
            if let until, log.date > until { return false }
            return true
        }
    }
}

public final class LogHabit: LogHabitUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(_ log: HabitLog) async throws {
        try await repo.upsert(log)
    }
}

public final class DeleteLog: DeleteLogUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(id: UUID) async throws {
        try await repo.deleteLog(id: id)
    }
}

public final class GetLogForDate: GetLogForDateUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(habitID: UUID, date: Date) async throws -> HabitLog? {
        // Get all logs for the habit
        let allLogs = try await repo.logs(for: habitID)

        // Business logic: Find log for specific date (comparing day only)
        let calendar = Calendar.current
        return allLogs.first { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }
    }
}

// MARK: - Tip Use Case Implementations
public final class GetAllTips: GetAllTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] { try await repo.getAllTips() }
}

public final class GetFeaturedTips: GetFeaturedTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] {
        // Business logic: Get featured tips and sort by order
        let featuredTips = try await repo.getFeaturedTips()
        return featuredTips.sorted { $0.order < $1.order }
    }
}

public final class GetTipById: GetTipByIdUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(id: UUID) async throws -> Tip? { try await repo.getTip(by: id) }
}

public final class GetTipsByCategory: GetTipsByCategoryUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(category: TipCategory) async throws -> [Tip] { try await repo.getTips(by: category) }
}

// MARK: - Onboarding Use Case Implementations
public final class GetOnboardingState: GetOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute() async throws -> OnboardingState { try await repo.getOnboardingState() }
}

public final class SaveOnboardingState: SaveOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute(_ state: OnboardingState) async throws { try await repo.saveOnboardingState(state) }
}

public final class CompleteOnboarding: CompleteOnboardingUseCase {
    private let onboardingRepo: OnboardingRepository
    private let profileRepo: ProfileRepository
    
    public init(repo: OnboardingRepository, profileRepo: ProfileRepository) { 
        self.onboardingRepo = repo 
        self.profileRepo = profileRepo
    }
    
    public func execute(userName: String?, hasNotifications: Bool) async throws {
        // Mark onboarding as completed
        try await onboardingRepo.markOnboardingCompleted(userName: userName, hasNotifications: hasNotifications)
        
        // Update user profile with the name if provided
        if let userName = userName, !userName.isEmpty {
            var profile = try await profileRepo.loadProfile()
            profile.name = userName
            try await profileRepo.saveProfile(profile)
        }
    }
}

// MARK: - User Management Use Cases

public protocol UpdateUserUseCase {
    func execute(_ user: User) async throws -> User
}

public final class UpdateUser: UpdateUserUseCase {
    private let userSession: any UserSessionProtocol
    
    public init(userSession: any UserSessionProtocol) {
        self.userSession = userSession
    }
    
    public func execute(_ user: User) async throws -> User {
        try await userSession.updateUser(user)
        return user
    }
}
