//
//  DataThresholdPlaceholderView.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import SwiftUI
import RitualistCore

/// Placeholder view shown when user doesn't meet data requirements for personality analysis
public struct PersonalityAnalysisInsuficientDataView: View {
    
    let requirements: [ThresholdRequirement]
    let estimatedDays: Int?
    
    public init(requirements: [ThresholdRequirement], estimatedDays: Int?) {
        self.requirements = requirements
        self.estimatedDays = estimatedDays
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            requirementsSection
            
            if let days = estimatedDays {
                estimatedTimeSection(days: days)
            }
            
            motivationSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Personality Insights Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Track more habits consistently to unlock your personality analysis")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 30-day context badge
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Analysis based on last 30 days of habit data")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.blue)
                Text("Requirements Progress")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(requirements, id: \.name) { requirement in
                    RequirementRowView(requirement: requirement)
                }
            }
        }
    }
    
    private func estimatedTimeSection(days: Int) -> some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(daysText(for: days))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var motivationSection: some View {
        VStack(spacing: 8) {
            Text("Why Personality Insights?")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Understanding your personality traits helps you choose habits that align with your natural tendencies, making long-term success more likely.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("We analyze your habit patterns over 30-day periods to ensure accurate, meaningful personality insights.")
                .font(.caption2)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }
    
    private func daysText(for days: Int) -> String {
        switch days {
        case 0:
            return "Available soon"
        case 1:
            return "About 1 day"
        case 2...7:
            return "About \(days) days"
        case 8...14:
            return "1-2 weeks"
        case 15...30:
            return "2-4 weeks"
        default:
            return "About a month"
        }
    }
}

private struct RequirementRowView: View {
    let requirement: ThresholdRequirement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(requirement.isMet ? .green : .gray)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(requirement.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(requirement.isMet ? .primary : .secondary)
                
                if !requirement.isMet {
                    Text(progressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if requirement.isMet {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .font(.caption)
                    .fontWeight(.semibold)
            } else {
                ProgressView(value: Double(requirement.currentValue), total: Double(requirement.requiredValue))
                    .frame(width: 40)
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var progressText: String {
        let current = requirement.currentValue
        let required = requirement.requiredValue
        let remaining = required - current
        
        switch requirement.category {
        case .habits:
            return "\(current) of \(required) habits"
        case .tracking:
            if requirement.name.contains("days") {
                return "\(current) of \(required) days"
            } else {
                return "\(current)% (need \(required)%)"
            }
        case .customization:
            return "\(current) of \(required) created"
        case .diversity:
            return "\(current) of \(required) categories"
        }
    }
}

#Preview {
    let sampleRequirements = [
        ThresholdRequirement(
            name: "Active Habits",
            description: "Track at least 5 active habits consistently",
            currentValue: 3,
            requiredValue: 5,
            category: .habits
        ),
        ThresholdRequirement(
            name: "Consistent Tracking",
            description: "Log habits for at least 7 consecutive days",
            currentValue: 4,
            requiredValue: 7,
            category: .tracking
        ),
        ThresholdRequirement(
            name: "Custom Habits",
            description: "Create at least 3 custom habits",
            currentValue: 3,
            requiredValue: 3,
            category: .customization
        )
    ]
    
    PersonalityAnalysisInsuficientDataView(
        requirements: sampleRequirements,
        estimatedDays: 5
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
