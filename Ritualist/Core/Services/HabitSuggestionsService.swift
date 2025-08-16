//
//  DefaultHabitSuggestionsService.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation
import RitualistCore

public final class DefaultHabitSuggestionsService: HabitSuggestionsService {
    
    public init() {}
    
    public func getSuggestions() -> [HabitSuggestion] {
        HabitSuggestionsData.getAllSuggestions()
    }
    
    public func getSuggestions(for categoryId: String) -> [HabitSuggestion] {
        HabitSuggestionsData.getSuggestions(for: categoryId)
    }
    
    public func getSuggestion(by id: String) -> HabitSuggestion? {
        HabitSuggestionsData.getSuggestion(by: id)
    }
}
