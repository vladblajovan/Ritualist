//
//  CreateHabitFromSuggestionResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public enum CreateHabitFromSuggestionResult {
    case success(habitId: UUID)
    case limitReached(message: String)
    case error(String)
}