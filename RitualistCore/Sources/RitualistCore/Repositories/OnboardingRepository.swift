//
//  OnboardingRepository.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public protocol OnboardingRepository: Sendable {
    func getOnboardingState() async throws -> OnboardingState?
    func saveOnboardingState(_ state: OnboardingState) async throws
}