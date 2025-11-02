//
//  DeleteSection.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import FactoryKit
import RitualistCore

public struct DeleteSection: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: HabitDetailViewModel
    @State private var showingDeleteAlert = false
    
    public var body: some View {
        Section {
            Button(Strings.Button.delete) {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
            .disabled(vm.isDeleting)
            .overlay(alignment: .trailing) {
                if vm.isDeleting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .alert(Strings.Dialog.deleteHabit, isPresented: $showingDeleteAlert) {
            Button(Strings.Button.cancel, role: .cancel) { }
            Button(Strings.Button.delete, role: .destructive) {
                Task {
                    let success = await vm.delete()
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(Strings.Dialog.cannotUndo)
        }
    }
}
