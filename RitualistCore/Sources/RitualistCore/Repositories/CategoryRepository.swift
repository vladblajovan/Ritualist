//
//  CategoryRepository.swift
//  RitualistCore
//
//  Created by Claude on 03.08.2025.
//

import Foundation

public protocol CategoryRepository {
    func getAllCategories() async throws -> [Category]
    func getCategory(by id: String) async throws -> Category?
    func getActiveCategories() async throws -> [Category]
    func getPredefinedCategories() async throws -> [Category]
    func getCustomCategories() async throws -> [Category]
    func createCustomCategory(_ category: Category) async throws
    func updateCategory(_ category: Category) async throws
    func deleteCategory(id: String) async throws
    func categoryExists(id: String) async throws -> Bool
    func categoryExists(name: String) async throws -> Bool
}