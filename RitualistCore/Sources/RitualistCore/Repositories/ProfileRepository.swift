//
//  ProfileRepository.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public protocol ProfileRepository {
    func loadProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
}