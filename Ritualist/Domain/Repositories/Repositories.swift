import Foundation

public protocol HabitRepository {
    func fetchAllHabits() async throws -> [Habit]
    func create(_ habit: Habit) async throws
    func update(_ habit: Habit) async throws
    func delete(id: UUID) async throws
}

public protocol LogRepository {
    func logs(for habitID: UUID) async throws -> [HabitLog]
    func upsert(_ log: HabitLog) async throws
    func deleteLog(id: UUID) async throws
}

public protocol ProfileRepository {
    func loadProfile() async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
}

public protocol TipRepository {
    func getAllTips() async throws -> [Tip]
    func getFeaturedTips() async throws -> [Tip]
    func getTip(by id: UUID) async throws -> Tip?
    func getTips(by category: TipCategory) async throws -> [Tip]
}

public protocol OnboardingRepository {
    func getOnboardingState() async throws -> OnboardingState
    func saveOnboardingState(_ state: OnboardingState) async throws
    func markOnboardingCompleted(userName: String?, hasNotifications: Bool) async throws
}

public protocol UserAuthRepository {
    func saveUser(_ user: User) async throws
    func getUser(by id: UUID) async throws -> User?
    func getUserByEmail(_ email: String) async throws -> User?
    func updateUser(_ user: User) async throws
    func deleteUser(id: UUID) async throws
    func getCurrentUserSession() async throws -> User?
    func clearUserSession() async throws
}
