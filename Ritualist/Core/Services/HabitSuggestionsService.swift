//
//  HabitSuggestionsService.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation
import RitualistCore

public protocol HabitSuggestionsService {
    func getSuggestions() -> [HabitSuggestion]
    func getSuggestions(for categoryId: String) -> [HabitSuggestion]
    func getSuggestion(by id: String) -> HabitSuggestion?
}

public final class DefaultHabitSuggestionsService: HabitSuggestionsService {
    
    public init() {}
    
    public func getSuggestions() -> [HabitSuggestion] {
        return HabitSuggestionsData.getAllSuggestions()
    }
    
    public func getSuggestions(for categoryId: String) -> [HabitSuggestion] {
        return HabitSuggestionsData.getSuggestions(for: categoryId)
    }
    
    public func getSuggestion(by id: String) -> HabitSuggestion? {
        return HabitSuggestionsData.getSuggestion(by: id)
    }
}
