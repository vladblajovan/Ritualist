//
//  ScheduleSection.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import FactoryKit
import RitualistCore

public struct ScheduleSection: View {
    @Bindable var vm: HabitDetailViewModel
    
    public var body: some View {
        Section(Strings.Form.schedule) {
            Picker(Strings.Form.frequency, selection: $vm.selectedSchedule) {
                Text(Strings.Form.daily).tag(ScheduleType.daily)
                Text(Strings.Form.specificDays).tag(ScheduleType.daysOfWeek)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            switch vm.selectedSchedule {
            case .daysOfWeek:
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    DaysOfWeekSelector(selectedDays: $vm.selectedDaysOfWeek)
                    
                    if !vm.isScheduleValid {
                        Text(Strings.Validation.selectAtLeastOneDay)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                            .transition(.opacity)
                    }
                }
            case .daily:
                EmptyView()
            }
        }
    }
}
