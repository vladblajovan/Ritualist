import Foundation

#if DEBUG
public struct DebugDatabaseStats: Sendable {
    public let habitsCount: Int
    public let logsCount: Int
    public let categoriesCount: Int
    public let profilesCount: Int

    public init(habitsCount: Int, logsCount: Int, categoriesCount: Int, profilesCount: Int) {
        self.habitsCount = habitsCount
        self.logsCount = logsCount
        self.categoriesCount = categoriesCount
        self.profilesCount = profilesCount
    }
}
#endif