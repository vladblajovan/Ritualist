//
//  UserAuthRepository.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public protocol UserAuthRepository {
    func saveUser(_ user: User) async throws
    func getUser(by id: UUID) async throws -> User?
    func getUserByEmail(_ email: String) async throws -> User?
    func updateUser(_ user: User) async throws
    func deleteUser(id: UUID) async throws
    func getCurrentUserSession() async throws -> User?
    func clearUserSession() async throws
}
