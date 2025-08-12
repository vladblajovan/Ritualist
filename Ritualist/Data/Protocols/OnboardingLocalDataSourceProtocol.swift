import Foundation

public protocol OnboardingLocalDataSourceProtocol {
    func load() async throws -> SDOnboardingState?
    func save(_ state: SDOnboardingState) async throws
}