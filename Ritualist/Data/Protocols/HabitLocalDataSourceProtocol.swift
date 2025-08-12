//
//  HabitLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import RitualistCore

public protocol HabitLocalDataSourceProtocol {
    func fetchAll() async throws -> [Habit]
    func upsert(_ habit: Habit) async throws
    func delete(id: UUID) async throws
}
