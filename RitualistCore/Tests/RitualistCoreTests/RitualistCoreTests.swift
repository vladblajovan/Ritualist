import XCTest
@testable import RitualistCore

final class RitualistCoreTests: XCTestCase {
    func testHabitCreation() {
        let habit = Habit(
            name: "Test Habit",
            emoji: "🧪",
            kind: .binary
        )
        
        XCTAssertEqual(habit.name, "Test Habit")
        XCTAssertEqual(habit.emoji, "🧪")
        XCTAssertEqual(habit.kind, .binary)
        XCTAssertTrue(habit.isActive)
    }
    
    func testUserProfileSubscription() {
        let profile = UserProfile(
            name: "Test User",
            subscriptionPlan: .monthly,
            subscriptionExpiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        )
        
        XCTAssertTrue(profile.hasActiveSubscription)
        XCTAssertTrue(profile.isPremiumUser)
    }
}