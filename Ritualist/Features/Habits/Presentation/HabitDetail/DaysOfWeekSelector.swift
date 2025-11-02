//
//  DaysOfWeekSelector.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import FactoryKit
import RitualistCore

public struct DaysOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>
    
    private let weekdays = [
        (1, Strings.DayOfWeek.mon), (2, Strings.DayOfWeek.tue), (3, Strings.DayOfWeek.wed), (4, Strings.DayOfWeek.thu),
        (5, Strings.DayOfWeek.fri), (6, Strings.DayOfWeek.sat), (7, Strings.DayOfWeek.sun)
    ]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(Strings.Form.selectDays)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.small) {
                ForEach(weekdays, id: \.0) { day, name in
                    Button {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        Text(name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 40, height: 40)
                            .background(
                                selectedDays.contains(day) ? AppColors.brand : Color(.systemGray5),
                                in: Circle()
                            )
                            .foregroundColor(
                                selectedDays.contains(day) ? .white : .primary
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
