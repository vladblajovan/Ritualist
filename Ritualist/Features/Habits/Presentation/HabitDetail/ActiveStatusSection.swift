//
//  ActiveStatusSection.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import SwiftUI
import FactoryKit
import RitualistCore

public struct ActiveStatusSection: View {
    @Bindable var vm: HabitDetailViewModel
    
    public var body: some View {
        Section {
            Button {
                Task {
                    await vm.toggleActiveStatus()
                }
            } label: {
                Label(
                    vm.isActive ? Strings.Button.deactivate : Strings.Button.activate,
                    systemImage: vm.isActive ? "pause.circle" : "play.circle"
                )
            }
            .foregroundColor(vm.isActive ? .orange : .green)
            .disabled(vm.isSaving)
            .overlay(alignment: .trailing) {
                if vm.isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
    }
}
