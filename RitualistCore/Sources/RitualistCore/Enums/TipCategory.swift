//
//  TipCategory.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum TipCategory: String, Codable, CaseIterable, Sendable {
    case gettingStarted = "getting_started"
    case tracking
    case motivation
    case advanced
}
