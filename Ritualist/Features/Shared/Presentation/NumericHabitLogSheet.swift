import SwiftUI
import RitualistCore
import FactoryKit
import TipKit

/// Direct sheet implementation without caching layer
public struct NumericHabitLogSheetDirect: View { 
    let habit: Habit
    let viewingDate: Date
    let timezone: TimeZone
    let onSave: (Double) async throws -> Void
    let onCancel: () -> Void
    let initialValue: Double?

    @Injected(\.getLogs) var getLogs
    @Injected(\.debugLogger) var logger
    @Injected(\.toastService) var toastService
    @State var currentValue: Double = 0.0
    @State var isLoading = true
    @State var isGlowing = false
    
    @State var value: Double = 0.0
    @State var extraMileText: String?
    @State var loadTask: Task<Void, Never>?
    @State var showCelebration = false
    @Environment(\.dismiss) private var dismiss

    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // MARK: - Dynamic Type Scaling
    @ScaledMetric(relativeTo: .title) var incrementButtonSize: CGFloat = 44
    @ScaledMetric(relativeTo: .title) var progressCircleSize: CGFloat = 120
    @ScaledMetric(relativeTo: .subheadline) var celebrationHeight: CGFloat = 30
    @ScaledMetric(relativeTo: .headline) var quickIncrementHeight: CGFloat = 36
    @ScaledMetric(relativeTo: .body) var buttonHeight: CGFloat = 44
    
    public init(
        habit: Habit,
        viewingDate: Date,
        timezone: TimeZone = .current,
        onSave: @escaping (Double) async throws -> Void,
        onCancel: @escaping () -> Void = {},
        initialValue: Double? = nil
    ) {
        self.habit = habit
        self.viewingDate = viewingDate
        self.timezone = timezone
        self.onSave = onSave
        self.onCancel = onCancel
        self.initialValue = initialValue
    }
    
    // MARK: - Computed Properties (delegating to ViewLogic for testability)

    var dailyTarget: Double {
        NumericHabitLogViewLogic.effectiveDailyTarget(from: habit.dailyTarget)
    }

    var progressPercentage: Double {
        NumericHabitLogViewLogic.progressPercentage(value: value, dailyTarget: dailyTarget)
    }

    var isCompleted: Bool {
        NumericHabitLogViewLogic.isCompleted(value: value, dailyTarget: dailyTarget)
    }

    var unitLabel: String {
        NumericHabitLogViewLogic.unitLabel(from: habit.unitLabel)
    }

    var maxAllowedValue: Double {
        NumericHabitLogViewLogic.maxAllowedValue(for: dailyTarget)
    }

    var isValidValue: Bool {
        NumericHabitLogViewLogic.isValidValue(value, dailyTarget: dailyTarget)
    }

    var canDecrement: Bool {
        NumericHabitLogViewLogic.canDecrement(value: value)
    }

    var canIncrement: Bool {
        NumericHabitLogViewLogic.canIncrement(value: value, dailyTarget: dailyTarget)
    }

    var quickIncrementAmounts: [Int] {
        NumericHabitLogViewLogic.quickIncrementAmounts(value: value, dailyTarget: dailyTarget)
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()

                // Centered content group (header + progress)
                VStack(spacing: Spacing.large) {
                    headerSection()

                    // Progress circle with +/- controls
                    VStack(spacing: Spacing.medium) {
                        progressSection(
                            progressPercentage: progressPercentage,
                            isCompleted: isCompleted,
                            canDecrement: canDecrement,
                            canIncrement: canIncrement,
                            showCelebration: $showCelebration
                        )

                        celebrationSection(extraMileText: extraMileText)
                    }

                    quickIncrementSection(amounts: quickIncrementAmounts)
                }

                Spacer()

                actionButtonsRow(isCompleted: isCompleted)
            }
            .navigationTitle(Strings.NumericHabitLog.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationDetents(isIPad ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .overlay { loadingOverlay(isLoading: isLoading) }
        .onAppear { handleOnAppear() }
        .onDisappear { handleOnDisappear() }
        .onChange(of: currentValue) { _, newValue in handleCurrentValueChange(newValue) }
        .onChange(of: value) { oldValue, newValue in handleValueChange(oldValue: oldValue, newValue: newValue) }
        .completionGlow(isGlowing: isGlowing)
    }
}
