import Foundation

public protocol OnboardingLocalDataSourceProtocol {
    @MainActor func load() async throws -> SDOnboardingState?
    @MainActor func save(_ state: SDOnboardingState) async throws
}