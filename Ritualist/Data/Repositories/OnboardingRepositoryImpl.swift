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
