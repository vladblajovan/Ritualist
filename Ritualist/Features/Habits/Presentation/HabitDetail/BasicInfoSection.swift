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
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            // Move to next field based on habit type
                            if vm.selectedKind == .numeric {
                                focusedField = .unitLabel
                            }
                        }
                        .onChange(of: vm.name) { _, _ in
                            // Validate for duplicates when name changes
                            Task {
                                await vm.validateForDuplicates()
                            }
                        }
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
                if vm.isDuplicateHabit {
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
            }
            
            if vm.selectedKind == .numeric {
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    HStack {
                        Text(Strings.Form.unit)
                        TextField(Strings.Form.unitPlaceholder, text: $vm.unitLabel)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .unitLabel)
                            .onSubmit {
                                focusedField = .dailyTarget
                            }
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
                    HStack(spacing: Spacing.small) {
                        Text(Strings.Form.dailyTarget)

                        Spacer()

                        // Minus button
                        Button {
                            if vm.dailyTarget > 1 {
                                vm.dailyTarget -= 1
                            } else if vm.dailyTarget > 0.5 {
                                vm.dailyTarget -= 0.5
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(vm.dailyTarget > 0.5 ? .blue : .gray)
                        }
                        .disabled(vm.dailyTarget <= 0.5)

                        // Text field
                        TextField(Strings.Form.target, value: $vm.dailyTarget, formatter: NumberUtils.habitValueFormatter())
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .focused($focusedField, equals: .dailyTarget)
                            .onSubmit {
                                focusedField = nil // Close keyboard
                            }

                        // Plus button
                        Button {
                            if vm.dailyTarget < 1 {
                                vm.dailyTarget += 0.5
                            } else if vm.dailyTarget < 10 {
                                vm.dailyTarget += 1
                            } else {
                                vm.dailyTarget += 5
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }

                    if !vm.isDailyTargetValid && focusedField != .dailyTarget {
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
