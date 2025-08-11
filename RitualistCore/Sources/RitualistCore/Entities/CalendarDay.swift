//
//  CalendarDay.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct CalendarDay {
    public let date: Date
    public let isCurrentMonth: Bool
    
    public init(date: Date, isCurrentMonth: Bool) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
    }
}
