//
//  PersonalityInsightsSettingsRow.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import SwiftUI
import FactoryKit

struct PersonalityInsightsSettingsRow: View {
    @State private var showingPersonalityInsights = false
    @StateObject private var personalityVM = resolve(\.personalityInsightsViewModel)
    
    var body: some View {
        let isEnabled = personalityVM.preferences?.isEnabled ?? false
        
        VStack(spacing: 0) {
            // Main personality insights row
            Button {
                showingPersonalityInsights = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isEnabled ? "person.crop.circle.badge.questionmark" : "person.crop.circle.badge.xmark")
                        .foregroundColor(isEnabled ? .blue : .gray)
                        .font(.title2)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("Personality Analysis")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(isEnabled ? .green : .red)
                        }
                        
                        if isEnabled {
                            Text("Tap to view insights")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 0) // Align with title above
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
        }
        .onAppear {
            Task {
                await personalityVM.loadPreferences()
            }
        }
        .onReceive(personalityVM.$preferences) { _ in
            // Force refresh when preferences change
        }
        .sheet(isPresented: $showingPersonalityInsights) {
            PersonalityInsightsView(viewModel: personalityVM)
                .deviceAwareSheetSizing(
                    compactMultiplier: (min: 0.97, ideal: 1.0, max: 1.0),
                    regularMultiplier: (min: 0.87, ideal: 1.0, max: 1.0),
                    largeMultiplier: (min: 0.78, ideal: 0.89, max: 1.0)
                )
                // Remove .presentationBackground for full transparency
        }
    }
    
    // MARK: - Helper Properties
    
    private var privacyStatusText: String {
        if personalityVM.isAnalysisEnabled {
            return "Analysis enabled - Tap to view insights"
        } else {
            return "Analysis disabled - Tap to enable"
        }
    }
}