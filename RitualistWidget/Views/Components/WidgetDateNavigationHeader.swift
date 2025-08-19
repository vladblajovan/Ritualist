//
//  WidgetDateNavigationHeader.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 19.08.2025.
//

import SwiftUI
import RitualistCore
import AppIntents

/// Reusable date navigation header component for widgets
/// Provides Previous/Next/Today navigation with size-adaptive UI
struct WidgetDateNavigationHeader: View {
    let entry: RemainingHabitsEntry
    let size: WidgetSize
    
    var body: some View {
        HStack(alignment: .center, spacing: sizingConfig.horizontalSpacing) {
            // Previous button
            navigationButton(
                icon: "chevron.left",
                intent: NavigateToPreviousDayIntent(),
                isEnabled: entry.navigationInfo.canGoBack
            )
            
            // Date display (expandable center section)
            HStack(spacing: 6) {
                dateText
                
                // Show "back to today" icon only for historical dates
                if !entry.navigationInfo.isViewingToday {
                    Button(intent: NavigateToTodayIntent()) {
                        Image(systemName: "calendar.circle")
                            .font(.caption)
                            .foregroundColor(.widgetBrand)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            // Next button
            navigationButton(
                icon: "chevron.right", 
                intent: NavigateToNextDayIntent(),
                isEnabled: entry.navigationInfo.canGoForward
            )
        }
        .padding(.horizontal, sizingConfig.horizontalPadding)
        .padding(.vertical, sizingConfig.verticalPadding)
    }
    
    // MARK: - View Components
    
    private var dateText: some View {
        Text(entry.navigationInfo.dateDisplayText)
            .font(sizingConfig.dateFont)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8) // Allow text scaling for small widgets
    }
    
    
    @ViewBuilder
    private func navigationButton(
        icon: String,
        intent: some AppIntent,
        isEnabled: Bool
    ) -> some View {
        if isEnabled {
            // Active button with intent
            Button(intent: intent) {
                navigationButtonContent(icon: icon, isEnabled: true)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // Inactive button without intent to prevent accidental taps
            navigationButtonContent(icon: icon, isEnabled: false)
        }
    }
    
    private func navigationButtonContent(icon: String, isEnabled: Bool) -> some View {
        Image(systemName: icon)
            .font(sizingConfig.buttonIconFont)
            .foregroundColor(isEnabled ? .widgetBrand : .secondary)
            .frame(width: sizingConfig.buttonSize, height: sizingConfig.buttonSize)
            .background(
                Circle()
                    .fill(isEnabled ? Color.widgetBrand.opacity(0.1) : Color.clear)
            )
            .overlay(
                Circle()
                    .stroke(
                        isEnabled ? Color.widgetBrand.opacity(0.3) : Color.secondary.opacity(0.2),
                        lineWidth: sizingConfig.buttonBorderWidth
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    // MARK: - Helper Properties
    
    private var sizingConfig: SizingConfiguration {
        SizingConfiguration.configuration(for: size)
    }
}

// MARK: - Widget Size Enum

enum WidgetSize {
    case small
    case medium  
    case large
}

// MARK: - Size Configuration

private struct SizingConfiguration {
    let dateFont: Font
    let buttonIconFont: Font
    let buttonSize: CGFloat
    let buttonBorderWidth: CGFloat
    let todayIndicatorSize: CGFloat
    let horizontalSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    
    static func configuration(for size: WidgetSize) -> SizingConfiguration {
        switch size {
        case .small:
            return SizingConfiguration(
                dateFont: .caption2,
                buttonIconFont: .caption2,
                buttonSize: 18,
                buttonBorderWidth: 0.5,
                todayIndicatorSize: 4,
                horizontalSpacing: 4,
                horizontalPadding: 4,
                verticalPadding: 2
            )
            
        case .medium:
            return SizingConfiguration(
                dateFont: .caption,
                buttonIconFont: .caption,
                buttonSize: 22,
                buttonBorderWidth: 0.75,
                todayIndicatorSize: 5,
                horizontalSpacing: 8,
                horizontalPadding: 8,
                verticalPadding: 4
            )
            
        case .large:
            return SizingConfiguration(
                dateFont: .body,
                buttonIconFont: .body,
                buttonSize: 28,
                buttonBorderWidth: 1.0,
                todayIndicatorSize: 6,
                horizontalSpacing: 12,
                horizontalPadding: 12,
                verticalPadding: 6
            )
        }
    }
}

// MARK: - Preview

#Preview("Small Widget Navigation") {
    let selectedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
    let entry = RemainingHabitsEntry(
        date: Date(),
        habitDisplayInfo: [],
        completionPercentage: 0.0,
        navigationInfo: navigationInfo
    )
    
    return WidgetDateNavigationHeader(entry: entry, size: .small)
        .frame(width: 155, height: 30)
        .background(Color(.systemBackground))
}

#Preview("Medium Widget Navigation - Today") {
    let navigationInfo = WidgetNavigationInfo(selectedDate: Date())
    let entry = RemainingHabitsEntry(
        date: Date(),
        habitDisplayInfo: [],
        completionPercentage: 0.0,
        navigationInfo: navigationInfo
    )
    
    return WidgetDateNavigationHeader(entry: entry, size: .medium)
        .frame(width: 338, height: 40)
        .background(Color(.systemBackground))
}

#Preview("Large Widget Navigation - Historical") {
    let selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
    let entry = RemainingHabitsEntry(
        date: Date(),
        habitDisplayInfo: [],
        completionPercentage: 0.0,
        navigationInfo: navigationInfo
    )
    
    return WidgetDateNavigationHeader(entry: entry, size: .large)
        .frame(width: 338, height: 50)
        .background(Color(.systemBackground))
}

#Preview("Navigation States") {
    VStack(spacing: 12) {
        // At earliest boundary (can't go back)
        WidgetDateNavigationHeader(
            entry: RemainingHabitsEntry(
                date: Date(),
                habitDisplayInfo: [],
                completionPercentage: 0.0,
                navigationInfo: WidgetNavigationInfo(selectedDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
            ),
            size: .medium
        )
        .background(Color.gray.opacity(0.1))
        
        // Middle state (can go both ways)
        WidgetDateNavigationHeader(
            entry: RemainingHabitsEntry(
                date: Date(),
                habitDisplayInfo: [],
                completionPercentage: 0.0,
                navigationInfo: WidgetNavigationInfo(selectedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
            ),
            size: .medium
        )
        .background(Color.gray.opacity(0.1))
        
        // Today (can't go forward)
        WidgetDateNavigationHeader(
            entry: RemainingHabitsEntry(
                date: Date(),
                habitDisplayInfo: [],
                completionPercentage: 0.0,
                navigationInfo: WidgetNavigationInfo(selectedDate: Date())
            ),
            size: .medium
        )
        .background(Color.gray.opacity(0.1))
    }
    .padding()
    .frame(width: 338)
    .background(Color(.systemBackground))
}