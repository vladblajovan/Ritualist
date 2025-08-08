import Foundation
import SwiftData

public final class SwiftDataStack {
    public let container: ModelContainer
    public var context: ModelContext { ModelContext(container) }
    public init() throws {
        let schema = Schema([SDHabit.self, SDHabitLog.self, SDUserProfile.self, SDOnboardingState.self, SDCategory.self, SDPersonalityProfile.self])
        container = try ModelContainer(for: schema)
    }
}
