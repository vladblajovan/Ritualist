//
//  DebugMenuDatabaseSection.swift
//  Ritualist
//

import SwiftUI

#if DEBUG
struct DebugMenuDatabaseSection: View {
    @Bindable var vm: SettingsViewModel
    @Binding var showingDeleteAlert: Bool

    var body: some View {
        Section("Database Management") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Database Statistics")
                        .font(.headline)

                    Spacer()

                    if vm.databaseStats == nil {
                        Button("Load Stats") {
                            Task {
                                await vm.loadDatabaseStats()
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                    }
                }

                if let stats = vm.databaseStats {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Habits:")
                            Spacer()
                            Text("\(stats.habitsCount)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Habit Logs:")
                            Spacer()
                            Text("\(stats.logsCount)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Categories:")
                            Spacer()
                            Text("\(stats.categoriesCount)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Profiles:")
                            Spacer()
                            Text("\(stats.profilesCount)")
                                .fontWeight(.medium)
                        }
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)

            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: vm.isClearingDatabase ? "hourglass" : "trash")
                        .foregroundColor(.red)

                    if vm.isClearingDatabase {
                        Text("Clearing Database...")
                    } else {
                        Text("Clear All Database Data")
                    }

                    Spacer()
                }
            }
            .disabled(vm.isClearingDatabase)
        }
    }
}
#endif
