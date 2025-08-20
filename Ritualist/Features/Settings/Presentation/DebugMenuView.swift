//
//  DebugMenuView.swift
//  Ritualist
//
//  Created by Claude on 18.08.2025.
//

import SwiftUI
import RitualistCore

#if DEBUG
struct DebugMenuView: View {
    @Bindable var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section {
                Text("Debug tools for development and testing. These options are only available in debug builds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Test Data") {
                // Test Data Population Button
                Button {
                    Task {
                        await vm.populateTestData()
                    }
                } label: {
                    HStack {
                        Image(systemName: vm.isPopulatingTestData ? "hourglass" : "testtube.2")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if vm.isPopulatingTestData {
                                Text("Populating Test Data...")
                                    .fontWeight(.medium)
                                
                                if !vm.testDataProgressMessage.isEmpty {
                                    Text(vm.testDataProgressMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Populate Test Data")
                                    .fontWeight(.medium)
                                
                                Text("Create habits, categories & 2-week history")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .disabled(vm.isPopulatingTestData || vm.isClearingDatabase)
                
                // Progress Bar
                if vm.isPopulatingTestData {
                    ProgressView(value: vm.testDataProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 0.5) // Make it thinner
                }
            }
            
            Section("Database Management") {
                // Database Statistics
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
                
                // Clear Database Button
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
            
            Section("Build Information") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Build Configuration:")
                        Spacer()
                        Text("Debug")
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("All Features Enabled:")
                        Spacer()
                        #if ALL_FEATURES_ENABLED
                        Text("Yes")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        #else
                        Text("No")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        #endif
                    }
                    
                    HStack {
                        Text("Subscription Enabled:")
                        Spacer()
                        #if SUBSCRIPTION_ENABLED
                        Text("Yes")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        #else
                        Text("No")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        #endif
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Debug Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            // Load database stats when the view appears
            await vm.loadDatabaseStats()
        }
        .alert("Clear Database?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                Task {
                    await vm.clearDatabase()
                }
            }
        } message: {
            Text("This will permanently delete all habits, logs, categories, and user data from the local database. This action cannot be undone.\n\nThis is useful for testing with a clean slate.")
        }
        .refreshable {
            await vm.loadDatabaseStats()
        }
    }
}

// Preview is available when the debug menu is shown from the main settings view
#endif