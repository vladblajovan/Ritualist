//
//  MockUserAuthRepositoryImpl.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public final class MockUserAuthRepositoryImpl: UserAuthRepository {
    private var users: [UUID: User] = [:]
    private var currentSession: User?
    
    public init() {
        // Pre-populate with test users
        let testUsers = [
            User(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                email: "free@test.com",
                name: "Free User",
                subscriptionPlan: .free
            ),
            User(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                email: "monthly@test.com",
                name: "Monthly Subscriber",
                subscriptionPlan: .monthly,
                subscriptionExpiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
            ),
            User(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                email: "annual@test.com",
                name: "Annual Subscriber",
                subscriptionPlan: .annual,
                subscriptionExpiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
            )
        ]
        
        for user in testUsers {
            users[user.id] = user
        }
    }
    
    public func saveUser(_ user: User) async throws {
        users[user.id] = user
    }
    
    public func getUser(by id: UUID) async throws -> User? {
        users[id]
    }
    
    public func getUserByEmail(_ email: String) async throws -> User? {
        users.values.first { $0.email == email }
    }
    
    public func updateUser(_ user: User) async throws {
        users[user.id] = user
        if currentSession?.id == user.id {
            currentSession = user
        }
    }
    
    public func deleteUser(id: UUID) async throws {
        users.removeValue(forKey: id)
        if currentSession?.id == id {
            currentSession = nil
        }
    }
    
    public func getCurrentUserSession() async throws -> User? {
        currentSession
    }
    
    public func clearUserSession() async throws {
        currentSession = nil
    }
}
