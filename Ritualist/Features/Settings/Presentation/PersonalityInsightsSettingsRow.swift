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
    @Injected(\.personalityInsightsViewModel) private var personalityVM
    
    var body: some View {
        Button {
            showingPersonalityInsights = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Personality Analysis")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Discover your Big Five personality traits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPersonalityInsights) {
            PersonalityInsightsView(viewModel: personalityVM)
        }
    }
}