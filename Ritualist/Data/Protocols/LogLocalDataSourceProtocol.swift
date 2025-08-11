//
//  LogLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

public protocol LogLocalDataSourceProtocol {
    func logs(for habitID: UUID) async throws -> [SDHabitLog]
    func upsert(_ log: SDHabitLog) async throws
    func delete(id: UUID) async throws
}
