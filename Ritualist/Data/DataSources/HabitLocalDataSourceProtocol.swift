//
//  HabitLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//


import Foundation
import SwiftData

public protocol HabitLocalDataSourceProtocol {
    @MainActor func fetchAll() async throws -> [SDHabit]
    @MainActor func upsert(_ habit: SDHabit) async throws
    @MainActor func delete(id: UUID) async throws
}