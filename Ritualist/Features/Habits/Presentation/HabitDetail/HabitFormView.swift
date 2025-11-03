//
//  HabitFormView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import FactoryKit
import RitualistCore

public struct HabitFormView: View {
    @Bindable var vm: HabitDetailViewModel
    
    public var body: some View {
        List {
            BasicInfoSection(vm: vm)
            CategorySection(vm: vm)
            ScheduleSection(vm: vm)
            ReminderSection(vm: vm)
            LocationConfigurationSection(vm: vm)
            AppearanceSection(vm: vm)
            if vm.isEditMode {
                ActiveStatusSection(vm: vm)
                DeleteSection(vm: vm)
            }
        }
        .listStyle(.insetGrouped)
        .task {
            await vm.loadCategories()
            await vm.checkLocationAuthStatus()
        }
    }
}
