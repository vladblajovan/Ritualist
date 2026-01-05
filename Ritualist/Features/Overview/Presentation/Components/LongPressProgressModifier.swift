//
//  LongPressProgressModifier.swift
//  Ritualist
//
//  A view modifier that adds long-press-to-complete behavior with a circular progress indicator.
//  Press and hold to auto-log a habit - the progress ring fills during the hold.
//

import SwiftUI
import RitualistCore

/// A view modifier that adds long-press gesture with visual progress feedback.
///
/// Uses native SwiftUI `onLongPressGesture(minimumDuration:pressing:perform:)` for proper
/// press state handling. Visual feedback only appears while actively pressing.
struct LongPressProgressModifier: ViewModifier {
    /// The duration required to complete the long-press (in seconds)
    let duration: TimeInterval

    /// Whether the long-press gesture is enabled
    let isEnabled: Bool

    /// Binding to report progress to parent (0.0 to 1.0)
    @Binding var progressBinding: Double

    /// Called when long-press begins
    let onStart: () -> Void

    /// Called when long-press completes successfully
    let onComplete: () -> Void

    /// Called when long-press is cancelled (released early)
    let onCancel: () -> Void

    @State private var isPressing = false
    @State private var didComplete = false
    @State private var animationTask: Task<Void, Never>?
    @State private var delayTask: Task<Void, Never>?

    /// Delay before showing visual feedback (filters out quick taps)
    private let visualFeedbackDelay: UInt64 = 150_000_000 // 150ms

    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: duration, pressing: { pressing in
                guard isEnabled else { return }
                handlePressingChange(pressing)
            }, perform: {
                guard isEnabled else { return }
                handleLongPressComplete()
            })
    }

    // MARK: - Gesture Handling

    private func handlePressingChange(_ pressing: Bool) {
        if pressing && !isPressing {
            // Press started - wait before showing visual feedback
            didComplete = false
            startPressWithDelay()
        } else if !pressing && isPressing {
            // Press ended - only cancel if it didn't complete successfully
            if !didComplete {
                cancelLongPress()
            }
            didComplete = false
        }
        isPressing = pressing
    }

    private func startPressWithDelay() {
        // Cancel any previous delay task
        delayTask?.cancel()
        animationTask?.cancel()
        progressBinding = 0.0

        // Wait before showing visual feedback to filter out quick taps
        delayTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: visualFeedbackDelay)
            guard !Task.isCancelled else { return }

            // Only now start the visual feedback
            startLongPressAnimation()
        }
    }

    private func startLongPressAnimation() {
        // Trigger start haptic
        HapticFeedbackService.shared.trigger(.light)
        onStart()

        // Calculate remaining duration after the delay
        let remainingDuration = duration - (Double(visualFeedbackDelay) / 1_000_000_000)

        // Animate progress from 0 to 1 over the remaining duration
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            withAnimation(.linear(duration: remainingDuration)) {
                progressBinding = 1.0
            }
        }
    }

    private func handleLongPressComplete() {
        didComplete = true
        delayTask?.cancel()
        animationTask?.cancel()

        // Ensure progress shows complete
        progressBinding = 1.0

        // Success haptic
        HapticFeedbackService.shared.trigger(.success)

        // Call completion
        onComplete()

        // Reset state after brief delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
            withAnimation(.easeOut(duration: 0.15)) {
                progressBinding = 0.0
            }
            isPressing = false
        }
    }

    private func cancelLongPress() {
        delayTask?.cancel()
        animationTask?.cancel()

        withAnimation(.easeOut(duration: 0.15)) {
            progressBinding = 0.0
        }

        isPressing = false
        onCancel()
    }
}

// MARK: - View Extension

extension View {
    /// Adds a long-press gesture with progress feedback via binding.
    ///
    /// - Parameters:
    ///   - duration: How long to hold before completion (default: 0.8s)
    ///   - isEnabled: Whether the gesture is active
    ///   - progress: Binding to receive progress updates (0.0 to 1.0)
    ///   - onStart: Called when press begins
    ///   - onComplete: Called when press completes successfully
    ///   - onCancel: Called when press is cancelled
    func longPressProgress(
        duration: TimeInterval = 0.8,
        isEnabled: Bool = true,
        progress: Binding<Double>,
        onStart: @escaping () -> Void = {},
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> some View {
        modifier(LongPressProgressModifier(
            duration: duration,
            isEnabled: isEnabled,
            progressBinding: progress,
            onStart: onStart,
            onComplete: onComplete,
            onCancel: onCancel
        ))
    }
}

// MARK: - Preview

struct LongPressProgressPreview: View {
    @State private var progress: Double = 0.0

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)

                    if progress > 0 {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                    }

                    Text("🏃")
                        .opacity(progress < 0.8 ? 1 : 0)
                    if progress >= 0.8 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.green)
                    }
                }
                Text("Morning Run")
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .longPressProgress(
                duration: 0.8,
                isEnabled: true,
                progress: $progress,
                onComplete: { print("Completed!") }
            )

            Text("Press and hold to complete")
                .font(CardDesign.caption)
                .foregroundStyle(.secondary)

            Text("Progress: \(Int(progress * 100))%")
                .font(CardDesign.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    LongPressProgressPreview()
}
