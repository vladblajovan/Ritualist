//
//  OnboardingRepository.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public protocol OnboardingRepository {
    func getOnboardingState() async throws -> OnboardingState
    func saveOnboardingState(_ state: OnboardingState) async throws
    func markOnboardingCompleted(userName: String?, hasNotifications: Bool) async throws
}
