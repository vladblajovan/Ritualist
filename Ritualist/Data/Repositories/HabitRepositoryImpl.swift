//
//  HabitRepositoryImpl.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData
import RitualistCore

public final class HabitRepositoryImpl: HabitRepository {
    private let local: HabitLocalDataSourceProtocol
    public init(local: HabitLocalDataSourceProtocol) { 
        self.local = local
    }
    public func fetchAllHabits() async throws -> [Habit] {
        try await local.fetchAll()
    }
    public func fetchHabit(by id: UUID) async throws -> Habit? {
        try await local.fetch(by: id)
    }
    public func create(_ habit: Habit) async throws {
        try await update(habit)
    }
    public func update(_ habit: Habit) async throws {
        try await local.upsert(habit)
    }
    public func delete(id: UUID) async throws {
        try await local.delete(id: id)
    }
    public func cleanupOrphanedHabits() async throws -> Int {
        try await local.cleanupOrphanedHabits()
    }
}
