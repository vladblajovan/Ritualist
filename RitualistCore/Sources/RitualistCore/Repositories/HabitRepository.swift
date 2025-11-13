//
//  HabitRepository.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public protocol HabitRepository {
    func fetchAllHabits() async throws -> [Habit]
    func fetchHabit(by id: UUID) async throws -> Habit?
    func update(_ habit: Habit) async throws
    func delete(id: UUID) async throws
    func cleanupOrphanedHabits() async throws -> Int
}