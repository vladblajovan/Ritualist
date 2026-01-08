//
//  CategoryDataSourceError.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public enum CategoryDataSourceError: LocalizedError {
    case categoryAlreadyExists
    case categoryNotFound
    case invalidCategoryId

    public var errorDescription: String? {
        switch self {
        case .categoryAlreadyExists:
            return "A category with this name already exists"
        case .categoryNotFound:
            return "Category not found"
        case .invalidCategoryId:
            return "Cannot save category with empty or invalid ID"
        }
    }
}