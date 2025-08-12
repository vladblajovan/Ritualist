//
//  HabitLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

public protocol HabitLocalDataSourceProtocol {
    func fetchAll() async throws -> [SDHabit]
    func upsert(_ habit: SDHabit) async throws
    func delete(id: UUID) async throws
}
