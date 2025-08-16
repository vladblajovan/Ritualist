//
//  ConfettiParticle.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import SwiftUI

public struct ConfettiParticle: View {
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    private let isVisible: Bool
    private let delay: Double
    private let angle: Double
    private let colors: [Color]
    
    public init(isVisible: Bool, delay: Double, angle: Double, colors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue, .green]) {
        self.isVisible = isVisible
        self.delay = delay
        self.angle = angle
        self.colors = colors
    }
    
    public var body: some View {
        Circle()
            .fill(colors.randomElement() ?? .yellow)
            .frame(width: 8, height: 8)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onChange(of: isVisible) { _, newValue in
                if newValue {
                    startParticleAnimation()
                } else {
                    resetParticle()
                }
            }
    }
    
    private func startParticleAnimation() {
        let distance: Double = 80
        let targetX = cos(angle * .pi / 180) * distance
        let targetY = sin(angle * .pi / 180) * distance
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.6)) {
                offset = CGSize(width: targetX, height: targetY)
                rotation = Double.random(in: 0...360)
                opacity = 1.0
            }
            
            // Fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.4)) {
                    opacity = 0
                }
            }
        }
    }
    
    private func resetParticle() {
        offset = .zero
        rotation = 0
        opacity = 0
    }
}
