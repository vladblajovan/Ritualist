//
//  CategoryRepository.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 03.08.2025.
//

import Foundation

public protocol CategoryRepository: Sendable {
    func getAllCategories() async throws -> [HabitCategory]
    func getCategory(by id: String) async throws -> HabitCategory?
    func getActiveCategories() async throws -> [HabitCategory]
    func getPredefinedCategories() async throws -> [HabitCategory]
    func getCustomCategories() async throws -> [HabitCategory]
    func createCustomCategory(_ category: HabitCategory) async throws
    func updateCategory(_ category: HabitCategory) async throws
    func deleteCategory(id: String) async throws
    func categoryExists(id: String) async throws -> Bool
    func categoryExists(name: String) async throws -> Bool
}
