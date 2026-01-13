//
//  BasicInfoSection.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import FactoryKit
import RitualistCore

public struct BasicInfoSection: View {
    @Bindable var vm: HabitDetailViewModel
    @FocusState private var focusedField: FormField?
    
    enum FormField: Hashable {
        case name
        case unitLabel
        case dailyTarget
    }
    
    public var body: some View {
        Section(Strings.Form.basicInformation) {
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                HStack {
                    Text(Strings.Form.name)
                    TextField(Strings.Form.habitName, text: $vm.name)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.sentences)
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            // Move to next field based on habit type
                            if vm.selectedKind == .numeric {
                                focusedField = .unitLabel
                            }
                        }
                        .onChange(of: vm.name) { _, _ in
                            // Validate for duplicates when name changes
                            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                            Task { @MainActor in
                                await vm.validateForDuplicates()
                            }
                        }
                        .accessibilityIdentifier(AccessibilityID.HabitDetail.nameField)
                        .accessibilityLabel("Habit name")
                        .accessibilityHint("Enter a name for your habit")
                }
                
                // Form validation feedback
                if !vm.isNameValid && focusedField != .name {
                    Text(Strings.Validation.nameRequired)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                        .transition(.opacity)
                }
                
                // Duplicate validation feedback
                if vm.duplicateValidationFailed {
                    HStack(spacing: Spacing.xxsmall) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(String(localized: "duplicateValidationFailed"))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.leading, 4)
                    .transition(.opacity)
                } else if vm.isDuplicateHabit {
                    HStack(spacing: Spacing.xxsmall) {
                        if vm.isValidatingDuplicate {
                            ProgressView()
                                .scaleEffect(0.6)
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        Text(String(localized: "duplicateHabitWarning"))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.leading, 4)
                    .transition(.opacity)
                }
            }
            
            HStack {
                Text(Strings.Form.type)
                Spacer()
                Picker(Strings.Form.type, selection: $vm.selectedKind) {
                    Text(Strings.Form.yesNo).tag(HabitKind.binary)
                    Text(Strings.Form.count).tag(HabitKind.numeric)
                }
                .pickerStyle(SegmentedPickerStyle())
                .accessibilityLabel("Habit type")
                .accessibilityHint("Choose between yes/no completion or numeric counting")
            }
            
            if vm.selectedKind == .numeric {
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    HStack {
                        Text(Strings.Form.unit)
                        TextField(Strings.Form.unitPlaceholder, text: $vm.unitLabel)
                            .textFieldStyle(.plain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .unitLabel)
                            .onSubmit {
                                focusedField = .dailyTarget
                            }
                            .accessibilityLabel("Unit label")
                            .accessibilityHint("Enter the unit of measurement, like glasses, minutes, or steps")
                    }
                    
                    if !vm.isUnitLabelValid && focusedField != .unitLabel {
                        Text(Strings.Validation.unitRequired)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                            .transition(.opacity)
                    }
                }
                
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    Stepper(value: $vm.dailyTarget, in: 1...10000, step: 1) {
                        HStack {
                            Text(Strings.Form.dailyTarget)
                            Spacer()
                            Text("\(Int(vm.dailyTarget))")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Daily target")
                    .accessibilityValue("\(Int(vm.dailyTarget)) \(vm.unitLabel.isEmpty ? "units" : vm.unitLabel)")
                    .accessibilityHint("Adjust to set your daily goal")

                    if !vm.isDailyTargetValid {
                        Text(Strings.Validation.targetGreaterThanZero)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                            .transition(.opacity)
                    }
                }
            }
        }
    }
}
