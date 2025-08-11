//
//  HabitRepository.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import RitualistCore

public protocol HabitRepository {
    func fetchAllHabits() async throws -> [Habit]
    func create(_ habit: Habit) async throws
    func update(_ habit: Habit) async throws
    func delete(id: UUID) async throws
}
