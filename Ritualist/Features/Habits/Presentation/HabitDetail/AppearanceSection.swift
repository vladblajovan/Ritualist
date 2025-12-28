//
//  AppearanceSection.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import FactoryKit
import RitualistCore

public struct AppearanceSection: View {
    @Bindable var vm: HabitDetailViewModel
    
    private let colors = [
        // Reds
        "#FF1744", "#DD2C00", "#F50057", "#FF6B6B",
        "#E91E63", "#FF4081",
        
        // Oranges 
        "#FF5722", "#FF6D00", "#FFAB00", "#FF9800",
        "#FF9F43", "#FFC107",
        
        // Yellows
        "#FFD600", "#FFFF00", "#FFEB3B", "#EEFF41",
        "#FFEAA7", "#FDCB6E",
        
        // Greens
        "#CDDC39", "#B2FF59", "#8BC34A", "#4CAF50",
        "#69F0AE", "#96CEB4", "#009688",
        
        // Teals/Cyans
        "#64FFDA", "#18FFFF", "#4ECDC4", "#00BCD4",
        
        // Blues
        "#2196F3", "#448AFF", "#2DA9E3", "#45B7D1",
        "#3F51B5",
        
        // Purples
        "#7C4DFF", "#6C5CE7", "#9C27B0", "#673AB7",
        "#A29BFE", "#D500F9",
        
        // Pinks/Magentas
        "#DDA0DD", "#FD79A8",
        
        // Neutrals
        "#795548", "#607D8B"
    ]
    
    private let emojis = [
        // Fitness & Health
        "💪", "🏃", "🏋️", "🚴", "🏊", "🧘",
        "💧", "🍎", "🥗", "🥛", "💤", "❤️",
        
        // Learning & Productivity
        "📚", "📖", "🧠", "📝", "💻", "⏰",
        "📊", "🎯", "✅", "💡", "🗓️", "📈",
        
        // Creative & Hobbies
        "🎨", "🎵", "🎸", "📸", "✍️", "🧵",
        
        // Sports & Activities
        "⚽", "🎾", "🏀", "🏸", "⛰️", "🚶",
        
        // Wellness & Mindfulness
        "🌱", "☀️", "🧘‍♀️", "🛁", "🕯️", "🙏",
        
        // Goals & Achievement
        "⭐", "🔥", "🏆", "🎖️", "🏅", "📍"
    ]
    
    public var body: some View {
        Section(Strings.Form.appearance) {
            HStack {
                Text(Strings.Form.emoji)
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.medium) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                vm.selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title2)
                                    .frame(width: 35, height: 35)
                                    .background(
                                        vm.selectedEmoji == emoji ? Color(.systemGray4) : Color.clear,
                                        in: Circle()
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            HStack {
                Text(Strings.Form.color)
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.medium) {
                        ForEach(colors, id: \.self) { colorHex in
                            Button {
                                vm.selectedColorHex = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 31, height: 33)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                vm.selectedColorHex == colorHex ? Color.primary : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}
