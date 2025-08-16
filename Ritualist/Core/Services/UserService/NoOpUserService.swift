//
//  NoOpUserService.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation
import Observation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class NoOpUserService: UserService {
    public let currentProfile = UserProfile()
    public let isPremiumUser = false
    
    public init() {}
    
    public func updateProfile(_ profile: UserProfile) async throws {}
    public func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {}
    public func syncWithiCloud() async throws {}
}