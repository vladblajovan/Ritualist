//
//  HabitSchedule.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum HabitSchedule: Codable, Equatable, Hashable {
    case daily
    case daysOfWeek(Set<Int>) // 1=Mon…7=Sun
    case timesPerWeek(Int) // 1…7
}
