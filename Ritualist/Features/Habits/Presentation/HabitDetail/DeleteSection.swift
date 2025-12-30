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
    @Bindable var vm: HabitDetailViewModel
    let onDelete: (() -> Void)?
    @State private var showingDeleteAlert = false
    
    public var body: some View {
        Section {
            Button {
                showingDeleteAlert = true
            } label: {
                Label(
                    Strings.Button.delete,
                    systemImage: "trash.circle"
                )
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
                Task { @MainActor in
                    let success = await vm.delete()
                    if success {
                        onDelete?()
                    }
                }
            }
        } message: {
            Text(Strings.Dialog.cannotUndo)
        }
    }
}
