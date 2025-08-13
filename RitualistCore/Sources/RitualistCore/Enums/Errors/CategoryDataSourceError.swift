//
//  CategoryDataSourceError.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public enum CategoryDataSourceError: Error {
    case categoryAlreadyExists
    case categoryNotFound
}