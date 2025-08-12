import Foundation
import RitualistCore

public protocol OnboardingLocalDataSourceProtocol {
    func load() async throws -> OnboardingState?
    func save(_ state: OnboardingState) async throws
}