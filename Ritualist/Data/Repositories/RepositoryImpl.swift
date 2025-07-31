import Foundation

public final class HabitRepositoryImpl: HabitRepository {
    private let local: HabitLocalDataSourceProtocol
    public init(local: HabitLocalDataSourceProtocol) { self.local = local }
    public func fetchAllHabits() async throws -> [Habit] {
        let sds = try await local.fetchAll()
        return try sds.map { try HabitMapper.fromSD($0) }
    }
    public func create(_ habit: Habit) async throws {
        try await update(habit)
    }
    public func update(_ habit: Habit) async throws {
        let sd = try HabitMapper.toSD(habit)
        try await local.upsert(sd)
    }
    public func delete(id: UUID) async throws {
        try await local.delete(id: id)
    }
}

public final class LogRepositoryImpl: LogRepository {
    private let local: LogLocalDataSourceProtocol
    public init(local: LogLocalDataSourceProtocol) { self.local = local }
    public func logs(for habitID: UUID) async throws -> [HabitLog] {
        let sds = try await local.logs(for: habitID)
        return sds.map { HabitLogMapper.fromSD($0) }
    }
    public func upsert(_ log: HabitLog) async throws {
        let sd = HabitLogMapper.toSD(log)
        try await local.upsert(sd)
    }
    public func deleteLog(id: UUID) async throws {
        try await local.delete(id: id)
    }
}

public final class ProfileRepositoryImpl: ProfileRepository {
    private let local: ProfileLocalDataSourceProtocol
    public init(local: ProfileLocalDataSourceProtocol) { self.local = local }
    public func loadProfile() async throws -> UserProfile {
        if let sd = try await local.load() {
            return ProfileMapper.fromSD(sd)
        } else {
            // Create profile with system defaults
            let defaultProfile = UserProfile(
                firstDayOfWeek: SystemPreferences.getSystemFirstDayOfWeek(),
                appearance: SystemPreferences.getSystemAppearance()
            )
            try await saveProfile(defaultProfile)
            return defaultProfile
        }
    }
    public func saveProfile(_ profile: UserProfile) async throws {
        let sd = ProfileMapper.toSD(profile)
        try await local.save(sd)
    }
}

public final class TipRepositoryImpl: TipRepository {
    private let local: TipLocalDataSourceProtocol
    public init(local: TipLocalDataSourceProtocol) { self.local = local }
    public func getAllTips() async throws -> [Tip] {
        try await local.getAllTips()
    }
    public func getFeaturedTips() async throws -> [Tip] {
        try await local.getFeaturedTips()
    }
    public func getTip(by id: UUID) async throws -> Tip? {
        try await local.getTip(by: id)
    }
    public func getTips(by category: TipCategory) async throws -> [Tip] {
        try await local.getTips(by: category)
    }
}

public final class OnboardingRepositoryImpl: OnboardingRepository {
    private let local: OnboardingLocalDataSourceProtocol
    public init(local: OnboardingLocalDataSourceProtocol) { self.local = local }
    
    public func getOnboardingState() async throws -> OnboardingState {
        if let sd = try await local.load() {
            return OnboardingMapper.fromSD(sd)
        } else {
            // Return default incomplete state
            return OnboardingState()
        }
    }
    
    public func saveOnboardingState(_ state: OnboardingState) async throws {
        let sd = OnboardingMapper.toSD(state)
        try await local.save(sd)
    }
    
    public func markOnboardingCompleted(userName: String?, hasNotifications: Bool) async throws {
        let completedState = OnboardingState(
            isCompleted: true,
            completedDate: Date(),
            userName: userName,
            hasGrantedNotifications: hasNotifications
        )
        try await saveOnboardingState(completedState)
    }
}

public final class MockUserAuthRepositoryImpl: UserAuthRepository {
    private var users: [UUID: User] = [:]
    private var currentSession: User?
    
    public init() {
        // Pre-populate with test users
        let testUsers = [
            User(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                email: "free@test.com",
                name: "Free User",
                subscriptionPlan: .free
            ),
            User(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                email: "monthly@test.com",
                name: "Monthly Subscriber",
                subscriptionPlan: .monthly,
                subscriptionExpiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
            ),
            User(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                email: "annual@test.com",
                name: "Annual Subscriber",
                subscriptionPlan: .annual,
                subscriptionExpiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
            )
        ]
        
        for user in testUsers {
            users[user.id] = user
        }
    }
    
    public func saveUser(_ user: User) async throws {
        users[user.id] = user
    }
    
    public func getUser(by id: UUID) async throws -> User? {
        users[id]
    }
    
    public func getUserByEmail(_ email: String) async throws -> User? {
        users.values.first { $0.email == email }
    }
    
    public func updateUser(_ user: User) async throws {
        users[user.id] = user
        if currentSession?.id == user.id {
            currentSession = user
        }
    }
    
    public func deleteUser(id: UUID) async throws {
        users.removeValue(forKey: id)
        if currentSession?.id == id {
            currentSession = nil
        }
    }
    
    public func getCurrentUserSession() async throws -> User? {
        currentSession
    }
    
    public func clearUserSession() async throws {
        currentSession = nil
    }
}
