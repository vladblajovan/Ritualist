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
    private let context: ModelContext?
    public init(local: HabitLocalDataSourceProtocol, context: ModelContext? = nil) { 
        self.local = local
        self.context = context
    }
    public func fetchAllHabits() async throws -> [Habit] {
        let sds = try await local.fetchAll()
        return try sds.map { try HabitMapper.fromSD($0) }
    }
    public func create(_ habit: Habit) async throws {
        try await update(habit)
    }
    public func update(_ habit: Habit) async throws {
        let sd = try HabitMapper.toSD(habit, context: context)
        try await local.upsert(sd)
    }
    public func delete(id: UUID) async throws {
        try await local.delete(id: id)
    }
}
