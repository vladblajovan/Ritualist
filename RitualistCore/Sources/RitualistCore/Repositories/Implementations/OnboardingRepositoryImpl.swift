//
//  OnboardingRepositoryImpl.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public final class OnboardingRepositoryImpl: OnboardingRepository {
    private let local: OnboardingLocalDataSourceProtocol
    public init(local: OnboardingLocalDataSourceProtocol) { self.local = local }

    public func getOnboardingState() async throws -> OnboardingState? {
        return try await local.load()
    }

    public func saveOnboardingState(_ state: OnboardingState) async throws {
        try await local.save(state)
    }
}
