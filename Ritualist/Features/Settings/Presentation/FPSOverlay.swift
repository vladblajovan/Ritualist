//
//  FPSOverlay.swift
//  Ritualist
//
//  Created by Claude on Performance Optimization
//

import SwiftUI
import QuartzCore

#if DEBUG
/// Lightweight FPS (frames per second) monitoring overlay
///
/// Displays real-time FPS in the top-right corner of the screen.
/// Color-coded: Green (55+), Orange (30-54), Red (<30)
///
/// Uses CADisplayLink for accurate frame counting
struct FPSOverlay: View {
    @StateObject private var fpsCounter = FPSCounter()

    var body: some View {
        VStack {
            HStack {
                Spacer()

                // FPS display badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(fpsColor)
                        .frame(width: 8, height: 8)

                    Text("\(Int(fpsCounter.fps)) FPS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.75))
                .cornerRadius(8)
                .padding(8)
            }
            Spacer()
        }
        .allowsHitTesting(false) // Don't intercept touches
    }

    // MARK: - FPS Color Logic

    private var fpsColor: Color {
        if fpsCounter.fps >= 55 {
            return .green       // Excellent performance
        } else if fpsCounter.fps >= 30 {
            return .orange      // Acceptable performance
        } else {
            return .red         // Poor performance
        }
    }
}

// MARK: - FPS Counter (CADisplayLink-based)

@MainActor
final class FPSCounter: ObservableObject {
    @Published private(set) var fps: Double = 60.0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0

    // PERFORMANCE LOGGING: Track performance metrics
    private var minFPS: Double = 60.0
    private var maxFPS: Double = 60.0
    private var fpsHistory: [Double] = []
    private var frameDropCount: Int = 0
    private var measurementCount: Int = 0
    private var lastFrameTimestamp: CFTimeInterval = 0

    init() {
        startDisplayLink()
        print("🎯 [FPS MONITOR] Started - Logging enabled")
        print("🎯 [FPS MONITOR] Target: 60 FPS | Acceptable: 30+ FPS | Poor: <30 FPS")
    }

    deinit {
        displayLink?.invalidate()
        // Note: Cannot log final stats from deinit due to actor isolation
        // Per-second logs and 10-second summaries provide comprehensive data
    }

    private func startDisplayLink() {
        // Create display link that fires on every frame
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func displayLinkFired(_ displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            lastFrameTimestamp = displayLink.timestamp
            return
        }

        frameCount += 1

        // PERFORMANCE LOGGING: Detect frame drops (>33ms between frames = dropped frame at 30fps)
        let frameDuration = displayLink.timestamp - lastFrameTimestamp
        if frameDuration > 0.033 {  // 33ms threshold
            frameDropCount += 1
            // Log significant frame drops (>50ms = multiple frames dropped)
            if frameDuration > 0.050 {
                let missedFrames = Int(frameDuration * 60)
                print("⚠️ [FPS MONITOR] Frame drop detected: \(Int(frameDuration * 1000))ms (\(missedFrames) frames)")
            }
        }
        lastFrameTimestamp = displayLink.timestamp

        let elapsed = displayLink.timestamp - lastTimestamp

        // Update FPS every second
        if elapsed >= 1.0 {
            fps = Double(frameCount) / elapsed
            measurementCount += 1

            // PERFORMANCE LOGGING: Track min/max
            if fps < minFPS {
                minFPS = fps
            }
            if fps > maxFPS {
                maxFPS = fps
            }

            // Store for average calculation
            fpsHistory.append(fps)
            if fpsHistory.count > 60 {  // Keep last 60 seconds
                fpsHistory.removeFirst()
            }

            // PERFORMANCE LOGGING: Log current FPS with context
            let avgFPS = fpsHistory.reduce(0.0, +) / Double(fpsHistory.count)
            let perfEmoji = fps >= 55 ? "✅" : (fps >= 30 ? "⚠️" : "🔴")

            print("\(perfEmoji) [FPS MONITOR] Current: \(Int(fps)) | Avg: \(Int(avgFPS)) | Min: \(Int(minFPS)) | Max: \(Int(maxFPS)) | Drops: \(frameDropCount)")

            // Log summary every 10 seconds
            if measurementCount % 10 == 0 {
                logPerformanceSummary()
            }

            // Reset for next measurement
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }

    // PERFORMANCE LOGGING: Summary report
    private func logPerformanceSummary() {
        let avgFPS = fpsHistory.reduce(0.0, +) / Double(max(fpsHistory.count, 1))
        print("📊 [FPS SUMMARY - \(measurementCount)s]")
        print("   Average: \(String(format: "%.1f", avgFPS)) FPS")
        print("   Min: \(Int(minFPS)) FPS | Max: \(Int(maxFPS)) FPS")
        print("   Frame Drops: \(frameDropCount)")
        print("   Performance: \(performanceRating(avgFPS))")
    }

    private func performanceRating(_ fps: Double) -> String {
        if fps >= 55 {
            return "Excellent (Smooth 60fps)"
        } else if fps >= 45 {
            return "Good (Minor drops)"
        } else if fps >= 30 {
            return "Acceptable (Noticeable lag)"
        } else {
            return "Poor (Significant lag)"
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()

        VStack(spacing: 20) {
            Text("FPS Overlay Demo")
                .font(.largeTitle)
                .foregroundColor(.white)

            Text("The FPS counter appears in top-right")
                .foregroundColor(.white.opacity(0.8))
        }

        FPSOverlay()
    }
}
#endif
