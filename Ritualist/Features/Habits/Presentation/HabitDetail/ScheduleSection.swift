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
                Text(Strings.Form.timesPerWeek).tag(ScheduleType.timesPerWeek)
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
            case .timesPerWeek:
                HStack {
                    Text(Strings.Form.timesPerWeekLabel)
                    Spacer()
                    Stepper("\(vm.timesPerWeek)", value: $vm.timesPerWeek, in: 1...7)
                }
            case .daily:
                EmptyView()
            }
        }
    }
}
