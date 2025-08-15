//
//  SlogansServiceProtocol.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public protocol SlogansServiceProtocol {
    /// Get a random slogan for the current time of day
    func getCurrentSlogan() -> String
    
    /// Get a random slogan for a specific time of day
    func getSlogan(for timeOfDay: TimeOfDay) -> String
    
}