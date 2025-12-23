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
    @Binding var showingCategoryManagement: Bool

    public var body: some View {
        List {
            BasicInfoSection(vm: vm)
            CategorySection(vm: vm, showingCategoryManagement: $showingCategoryManagement)
            ScheduleSection(vm: vm)
            ReminderSection(vm: vm)
            LocationConfigurationSection(vm: vm)
            AppearanceSection(vm: vm)
            if vm.isEditMode {
                StartDateSection(vm: vm)
                ActiveStatusSection(vm: vm)
                DeleteSection(vm: vm)
            }
        }
        .listStyle(.insetGrouped)
        // Note: Categories and location status are loaded in ViewModel init
        .sheet(item: $vm.paywallItem) { item in
            PaywallView(vm: item.viewModel)
        }
    }
}
