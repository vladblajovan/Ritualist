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
    public func loadProfile() async throws -> UserProfile? {
        return try await local.load()
    }
    public func saveProfile(_ profile: UserProfile) async throws {
        try await local.save(profile)
    }
}
