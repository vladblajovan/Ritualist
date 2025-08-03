//
//  ProfileRepositoryImpl.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public final class ProfileRepositoryImpl: ProfileRepository {
    private let local: ProfileLocalDataSourceProtocol
    public init(local: ProfileLocalDataSourceProtocol) { self.local = local }
    public func loadProfile() async throws -> UserProfile {
        if let sd = try await local.load() {
            return ProfileMapper.fromSD(sd)
        } else {
            // Create profile with system defaults
            let defaultProfile = UserProfile(
                appearance: AppearanceManager.getSystemAppearance()
            )
            try await saveProfile(defaultProfile)
            return defaultProfile
        }
    }
    public func saveProfile(_ profile: UserProfile) async throws {
        let sd = ProfileMapper.toSD(profile)
        try await local.save(sd)
    }
}
