import Testing
@testable import RitualistCore

/// Tests for NumericHabitLogViewLogic - demonstrates testable numeric habit logic
@Suite("NumericHabitLogViewLogic Tests")
struct NumericHabitLogViewLogicTests {

    // MARK: - Effective Daily Target Tests

    @Test("Effective target with nil returns 1.0")
    func effectiveTargetNil() {
        let target = NumericHabitLogViewLogic.effectiveDailyTarget(from: nil)
        #expect(target == 1.0)
    }

    @Test("Effective target with zero returns 1.0")
    func effectiveTargetZero() {
        let target = NumericHabitLogViewLogic.effectiveDailyTarget(from: 0)
        #expect(target == 1.0)
    }

    @Test("Effective target with negative returns 1.0")
    func effectiveTargetNegative() {
        let target = NumericHabitLogViewLogic.effectiveDailyTarget(from: -10)
        #expect(target == 1.0)
    }

    @Test("Effective target with positive value returns that value")
    func effectiveTargetPositive() {
        let target = NumericHabitLogViewLogic.effectiveDailyTarget(from: 100)
        #expect(target == 100)
    }

    @Test("Effective target with 0.5 returns 1.0 (minimum)")
    func effectiveTargetBelowMinimum() {
        let target = NumericHabitLogViewLogic.effectiveDailyTarget(from: 0.5)
        #expect(target == 1.0)
    }

    // MARK: - Progress Percentage Tests

    @Test("Progress percentage at 0 of 100")
    func progressPercentageZero() {
        let progress = NumericHabitLogViewLogic.progressPercentage(value: 0, dailyTarget: 100)
        #expect(progress == 0.0)
    }

    @Test("Progress percentage at 50 of 100")
    func progressPercentageHalf() {
        let progress = NumericHabitLogViewLogic.progressPercentage(value: 50, dailyTarget: 100)
        #expect(progress == 0.5)
    }

    @Test("Progress percentage at 100 of 100")
    func progressPercentageComplete() {
        let progress = NumericHabitLogViewLogic.progressPercentage(value: 100, dailyTarget: 100)
        #expect(progress == 1.0)
    }

    @Test("Progress percentage over target is capped at 1.0")
    func progressPercentageOverTarget() {
        let progress = NumericHabitLogViewLogic.progressPercentage(value: 150, dailyTarget: 100)
        #expect(progress == 1.0)
    }

    @Test("Progress percentage negative value is clamped to 0.0")
    func progressPercentageNegative() {
        let progress = NumericHabitLogViewLogic.progressPercentage(value: -10, dailyTarget: 100)
        #expect(progress == 0.0)
    }

    @Test("Progress percentage with zero target returns 0")
    func progressPercentageZeroTarget() {
        let progress = NumericHabitLogViewLogic.progressPercentage(value: 50, dailyTarget: 0)
        #expect(progress == 0.0)
    }

    // MARK: - Is Completed Tests

    @Test("Is completed when value equals target")
    func isCompletedAtTarget() {
        let completed = NumericHabitLogViewLogic.isCompleted(value: 100, dailyTarget: 100)
        #expect(completed == true)
    }

    @Test("Is completed when value exceeds target")
    func isCompletedOverTarget() {
        let completed = NumericHabitLogViewLogic.isCompleted(value: 150, dailyTarget: 100)
        #expect(completed == true)
    }

    @Test("Is not completed when value below target")
    func isNotCompletedBelowTarget() {
        let completed = NumericHabitLogViewLogic.isCompleted(value: 99, dailyTarget: 100)
        #expect(completed == false)
    }

    // MARK: - Max Allowed Value Tests

    @Test("Max allowed value for target 100 (10% + base)")
    func maxAllowedValueTarget100() {
        // 100 + max(50, 10) = 150, capped at min(150, 200) = 150
        let maxValue = NumericHabitLogViewLogic.maxAllowedValue(for: 100)
        #expect(maxValue == 150)
    }

    @Test("Max allowed value for target 1000 (10% > 50)")
    func maxAllowedValueTarget1000() {
        // 1000 + max(50, 100) = 1100, capped at min(1100, 2000) = 1100
        let maxValue = NumericHabitLogViewLogic.maxAllowedValue(for: 1000)
        #expect(maxValue == 1100)
    }

    @Test("Max allowed value for target 10 (capped at 2x)")
    func maxAllowedValueTarget10() {
        // 10 + max(50, 1) = 60, capped at min(60, 20) = 20
        let maxValue = NumericHabitLogViewLogic.maxAllowedValue(for: 10)
        #expect(maxValue == 20)
    }

    @Test("Max allowed value for target 500")
    func maxAllowedValueTarget500() {
        // 500 + max(50, 50) = 550, capped at min(550, 1000) = 550
        let maxValue = NumericHabitLogViewLogic.maxAllowedValue(for: 500)
        #expect(maxValue == 550)
    }

    @Test("Max allowed value for target 25 (2x cap applies)")
    func maxAllowedValueTarget25() {
        // 25 + max(50, 2.5) = 75, capped at min(75, 50) = 50
        let maxValue = NumericHabitLogViewLogic.maxAllowedValue(for: 25)
        #expect(maxValue == 50)
    }

    // MARK: - Validation Tests

    @Test("Valid value at 0")
    func isValidValueZero() {
        let valid = NumericHabitLogViewLogic.isValidValue(0, dailyTarget: 100)
        #expect(valid == true)
    }

    @Test("Valid value at target")
    func isValidValueAtTarget() {
        let valid = NumericHabitLogViewLogic.isValidValue(100, dailyTarget: 100)
        #expect(valid == true)
    }

    @Test("Valid value at max")
    func isValidValueAtMax() {
        // Max for 100 is 150
        let valid = NumericHabitLogViewLogic.isValidValue(150, dailyTarget: 100)
        #expect(valid == true)
    }

    @Test("Invalid value over max")
    func isInvalidValueOverMax() {
        let valid = NumericHabitLogViewLogic.isValidValue(151, dailyTarget: 100)
        #expect(valid == false)
    }

    @Test("Invalid value negative")
    func isInvalidValueNegative() {
        let valid = NumericHabitLogViewLogic.isValidValue(-1, dailyTarget: 100)
        #expect(valid == false)
    }

    // MARK: - Can Decrement/Increment Tests

    @Test("Can decrement when value > 0")
    func canDecrementPositive() {
        let canDec = NumericHabitLogViewLogic.canDecrement(value: 10)
        #expect(canDec == true)
    }

    @Test("Cannot decrement when value = 0")
    func cannotDecrementAtZero() {
        let canDec = NumericHabitLogViewLogic.canDecrement(value: 0)
        #expect(canDec == false)
    }

    @Test("Can increment below max")
    func canIncrementBelowMax() {
        // Max for 100 is 150
        let canInc = NumericHabitLogViewLogic.canIncrement(value: 100, dailyTarget: 100)
        #expect(canInc == true)
    }

    @Test("Cannot increment at max")
    func cannotIncrementAtMax() {
        // Max for 100 is 150
        let canInc = NumericHabitLogViewLogic.canIncrement(value: 150, dailyTarget: 100)
        #expect(canInc == false)
    }

    // MARK: - Remaining Tests

    @Test("Remaining at 0 of 100")
    func remainingAtZero() {
        let rem = NumericHabitLogViewLogic.remaining(value: 0, dailyTarget: 100)
        #expect(rem == 100)
    }

    @Test("Remaining at 50 of 100")
    func remainingHalfway() {
        let rem = NumericHabitLogViewLogic.remaining(value: 50, dailyTarget: 100)
        #expect(rem == 50)
    }

    @Test("Remaining at target")
    func remainingAtTarget() {
        let rem = NumericHabitLogViewLogic.remaining(value: 100, dailyTarget: 100)
        #expect(rem == 0)
    }

    @Test("Remaining over target")
    func remainingOverTarget() {
        let rem = NumericHabitLogViewLogic.remaining(value: 150, dailyTarget: 100)
        #expect(rem == 0)
    }

    @Test("Remaining to max when at target")
    func remainingToMaxAtTarget() {
        // Max for 100 is 150, so 150 - 100 = 50
        let rem = NumericHabitLogViewLogic.remainingToMax(value: 100, dailyTarget: 100)
        #expect(rem == 50)
    }

    @Test("Remaining to max when at max")
    func remainingToMaxAtMax() {
        let rem = NumericHabitLogViewLogic.remainingToMax(value: 150, dailyTarget: 100)
        #expect(rem == 0)
    }

    // MARK: - Quick Increment Amounts Tests

    @Test("Quick increment amounts for remaining < 5")
    func quickIncrementVeryClose() {
        // 97 of 100 = 3 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 97, dailyTarget: 100)
        #expect(amounts.isEmpty)
    }

    @Test("Quick increment amounts for remaining 5-19")
    func quickIncrementSmall() {
        // 90 of 100 = 10 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 90, dailyTarget: 100)
        #expect(amounts == [2, 5])
    }

    @Test("Quick increment amounts for remaining 20-99")
    func quickIncrementMediumSmall() {
        // 50 of 100 = 50 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 50, dailyTarget: 100)
        #expect(amounts == [5, 10])
    }

    @Test("Quick increment amounts for remaining 100-499")
    func quickIncrementMedium() {
        // 0 of 200 = 200 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 0, dailyTarget: 200)
        #expect(amounts == [10, 50])
    }

    @Test("Quick increment amounts for remaining 500-1999")
    func quickIncrementLarge() {
        // 0 of 1000 = 1000 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 0, dailyTarget: 1000)
        #expect(amounts == [100, 500])
    }

    @Test("Quick increment amounts for remaining 2000-9999")
    func quickIncrementVeryLarge() {
        // 0 of 5000 = 5000 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 0, dailyTarget: 5000)
        #expect(amounts == [500, 1000])
    }

    @Test("Quick increment amounts for remaining 10000-49999")
    func quickIncrementHuge() {
        // 0 of 20000 = 20000 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 0, dailyTarget: 20000)
        #expect(amounts == [1000, 5000])
    }

    @Test("Quick increment amounts for remaining >= 50000")
    func quickIncrementMassive() {
        // 0 of 100000 = 100000 remaining
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 0, dailyTarget: 100000)
        #expect(amounts == [5000, 10000])
    }

    @Test("Quick increment uses remainingToMax after completion")
    func quickIncrementAfterCompletion() {
        // 100 of 100, max is 150, remainingToMax = 50
        // 50 remaining should give [5, 10]
        let amounts = NumericHabitLogViewLogic.quickIncrementAmounts(value: 100, dailyTarget: 100)
        #expect(amounts == [5, 10])
    }

    // MARK: - Format Amount Tests

    @Test("Format amount under 1000")
    func formatAmountUnder1000() {
        #expect(NumericHabitLogViewLogic.formatAmount(500) == "500")
        #expect(NumericHabitLogViewLogic.formatAmount(999) == "999")
        #expect(NumericHabitLogViewLogic.formatAmount(1) == "1")
    }

    @Test("Format amount exactly 1000")
    func formatAmount1000() {
        #expect(NumericHabitLogViewLogic.formatAmount(1000) == "1K")
    }

    @Test("Format amount with whole thousands")
    func formatAmountWholeThousands() {
        #expect(NumericHabitLogViewLogic.formatAmount(2000) == "2K")
        #expect(NumericHabitLogViewLogic.formatAmount(5000) == "5K")
        #expect(NumericHabitLogViewLogic.formatAmount(10000) == "10K")
    }

    @Test("Format amount with decimal thousands")
    func formatAmountDecimalThousands() {
        #expect(NumericHabitLogViewLogic.formatAmount(1500) == "1.5K")
        #expect(NumericHabitLogViewLogic.formatAmount(2500) == "2.5K")
    }

    // MARK: - Unit Label Tests

    @Test("Unit label with valid string")
    func unitLabelValid() {
        let label = NumericHabitLogViewLogic.unitLabel(from: "steps")
        #expect(label == "steps")
    }

    @Test("Unit label with nil")
    func unitLabelNil() {
        let label = NumericHabitLogViewLogic.unitLabel(from: nil)
        #expect(label == "units")
    }

    @Test("Unit label with empty string")
    func unitLabelEmpty() {
        let label = NumericHabitLogViewLogic.unitLabel(from: "")
        #expect(label == "units")
    }

    @Test("Unit label with whitespace only")
    func unitLabelWhitespace() {
        let label = NumericHabitLogViewLogic.unitLabel(from: "   ")
        #expect(label == "units")
    }

    @Test("Unit label trims whitespace")
    func unitLabelTrims() {
        let label = NumericHabitLogViewLogic.unitLabel(from: "  calories  ")
        #expect(label == "calories")
    }
}
