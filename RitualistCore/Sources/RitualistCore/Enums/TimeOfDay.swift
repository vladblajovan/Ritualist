//
//  TimeOfDay.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public enum TimeOfDay: CaseIterable {
    case morning    // Until 11:00
    case noon       // Between 11:00 and 16:00
    case evening    // After 16:00
}