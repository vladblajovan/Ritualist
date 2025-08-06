import SwiftUI
import FactoryKit

public struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: HabitDetailViewModel
    @ObservationIgnored @Injected(\.categoryManagementViewModel) var categoryManagementVM
    
    public init(vm: HabitDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView(Strings.Loading.habit)
                } else if let error = vm.error {
                    ErrorView(
                        title: Strings.Error.failedLoadHabit,
                        message: error.localizedDescription
                    ) {
                        await vm.retry()
                    }
                } else {
                    HabitFormView(vm: vm)
                }
            }
            .navigationTitle(vm.isEditMode ? Strings.Navigation.editHabit : Strings.Navigation.newHabit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Button.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveHabit()
                        }
                    } label: {
                        HStack(spacing: Spacing.xsmall) {
                            if vm.isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(vm.isSaving ? Strings.Loading.saving : Strings.Button.save)
                        }
                    }
                    .disabled(vm.isSaving || !vm.isFormValid)
                    .animation(.easeInOut(duration: 0.2), value: vm.isSaving)
                }
            }
        }
    }
    
    private func saveHabit() async {
        let success = await vm.save()
        if success {
            dismiss()
        }
    }
}

private struct HabitFormView: View {
    @Bindable var vm: HabitDetailViewModel
    
    var body: some View {
        Form {
            BasicInfoSection(vm: vm)
            CategorySection(vm: vm)
            ScheduleSection(vm: vm)
            ReminderSection(vm: vm)
            AppearanceSection(vm: vm)
            if vm.isEditMode {
                ActiveStatusSection(vm: vm)
                DeleteSection(vm: vm)
            }
        }
        .task {
            await vm.loadCategories()
        }
    }
}

private struct BasicInfoSection: View {
    @Bindable var vm: HabitDetailViewModel
    @FocusState private var focusedField: FormField?
    
    enum FormField: Hashable {
        case name
        case unitLabel
        case dailyTarget
    }
    
    var body: some View {
        Section(Strings.Form.basicInformation) {
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                HStack {
                    Text(Strings.Form.name)
                    TextField(Strings.Form.habitName, text: $vm.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                    HStack {
                        Text(Strings.Form.dailyTarget)
                        TextField(Strings.Form.target, value: $vm.dailyTarget, formatter: NumberUtils.habitValueFormatter())
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .dailyTarget)
                            .onSubmit {
                                focusedField = nil // Close keyboard
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

private struct ScheduleSection: View {
    @Bindable var vm: HabitDetailViewModel
    
    var body: some View {
        Section(Strings.Form.schedule) {
            Picker(Strings.Form.frequency, selection: $vm.selectedSchedule) {
                Text(Strings.Form.daily).tag(ScheduleType.daily)
                Text(Strings.Form.specificDays).tag(ScheduleType.daysOfWeek)
                Text(Strings.Form.timesPerWeek).tag(ScheduleType.timesPerWeek)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            switch vm.selectedSchedule {
            case .daysOfWeek:
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    DaysOfWeekSelector(selectedDays: $vm.selectedDaysOfWeek)
                    
                    if !vm.isScheduleValid {
                        Text(Strings.Validation.selectAtLeastOneDay)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                            .transition(.opacity)
                    }
                }
            case .timesPerWeek:
                HStack {
                    Text(Strings.Form.timesPerWeekLabel)
                    Spacer()
                    Stepper("\(vm.timesPerWeek)", value: $vm.timesPerWeek, in: 1...7)
                }
            case .daily:
                EmptyView()
            }
        }
    }
}

private struct DaysOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>
    
    private let weekdays = [
        (1, Strings.DayOfWeek.mon), (2, Strings.DayOfWeek.tue), (3, Strings.DayOfWeek.wed), (4, Strings.DayOfWeek.thu),
        (5, Strings.DayOfWeek.fri), (6, Strings.DayOfWeek.sat), (7, Strings.DayOfWeek.sun)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(Strings.Form.selectDays)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.small) {
                ForEach(weekdays, id: \.0) { day, name in
                    Button {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        Text(name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 40, height: 40)
                            .background(
                                selectedDays.contains(day) ? AppColors.brand : Color(.systemGray5),
                                in: Circle()
                            )
                            .foregroundColor(
                                selectedDays.contains(day) ? .white : .primary
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

private struct CategorySection: View {
    @Bindable var vm: HabitDetailViewModel
    @State private var showingAddCustomCategory = false
    @State private var showingCategoryManagement = false
    @ObservationIgnored @Injected(\.categoryManagementViewModel) var categoryManagementVM
    
    var body: some View {
        Section {
            // Show category selection for new habits or editable habits (not from suggestions)
            if !vm.isEditMode || (vm.originalHabit?.suggestionId == nil) {
                CategorySelectionView(
                    selectedCategory: $vm.selectedCategory,
                    categories: vm.categories,
                    isLoading: vm.isLoadingCategories,
                    showAddCustomOption: true,
                    onCategorySelect: { category in
                        vm.selectCategory(category)
                    },
                    onAddCustomCategory: {
                        showingAddCustomCategory = true
                    },
                    onManageCategories: {
                        showingCategoryManagement = true
                    }
                )
                .padding(.vertical, Spacing.small)
            } else if let originalHabit = vm.originalHabit, originalHabit.suggestionId != nil {
                // Show read-only category info for habits from suggestions
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text("Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(String(localized: "fromSuggestion"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Spacing.small)
                            .padding(.vertical, Spacing.xxsmall)
                            .background(AppColors.systemGray6, in: Capsule())
                    }
                    
                    Text(String(localized: "habitSuggestionRestriction"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, Spacing.small)
            }
            
            // Error state
            if let error = vm.categoriesError {
                Text(String(format: String(localized: "failedLoadCategories"), error.localizedDescription))
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingAddCustomCategory) {
            AddCustomCategorySheet { name, emoji in
                await vm.createCustomCategory(name: name, emoji: emoji)
            }
        }
        .onChange(of: showingAddCustomCategory) { _, isShowing in
            if !isShowing {
                // Refresh categories when sheet is dismissed
                Task {
                    await vm.loadCategories()
                }
            }
        }
        .sheet(isPresented: $showingCategoryManagement) {
            categoryManagementSheet
        }
    }
    
    @ViewBuilder
    private var categoryManagementSheet: some View {
        NavigationStack {
            CategoryManagementView(vm: categoryManagementVM)
        }
    }
}

private struct AppearanceSection: View {
    @Bindable var vm: HabitDetailViewModel
    
    private let colors = [
        "#2DA9E3", "#FF6B6B", "#4ECDC4", "#45B7D1",
        "#96CEB4", "#FFEAA7", "#DDA0DD", "#FF9F43",
        "#6C5CE7", "#A29BFE", "#FD79A8", "#FDCB6E"
    ]
    
    private let emojis = [
        "💪", "🏃", "📚", "💧", "🧘", "🎯",
        "⭐", "🔥", "📝", "🎵", "🌱", "☀️",
        "🍎", "💤", "🏠", "❤️", "🧠", "✨"
    ]
    
    var body: some View {
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
                                    .fill(AppColors.brand ?? AppColors.brand)
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

private struct DeleteSection: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: HabitDetailViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Section {
            Button(Strings.Dialog.deleteHabit) {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
            .disabled(vm.isDeleting)
            .overlay(alignment: .trailing) {
                if vm.isDeleting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .alert(Strings.Dialog.deleteHabit, isPresented: $showingDeleteAlert) {
            Button(Strings.Button.cancel, role: .cancel) { }
            Button(Strings.Button.delete, role: .destructive) {
                Task {
                    let success = await vm.delete()
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(Strings.Dialog.cannotUndo)
        }
    }
}

private struct ActiveStatusSection: View {
    @Bindable var vm: HabitDetailViewModel
    
    var body: some View {
        Section {
            Button {
                Task {
                    await vm.toggleActiveStatus()
                }
            } label: {
                Label(
                    vm.isActive ? Strings.Button.deactivate : Strings.Button.activate,
                    systemImage: vm.isActive ? "pause.circle" : "play.circle"
                )
            }
            .foregroundColor(vm.isActive ? .orange : .green)
            .disabled(vm.isSaving)
            .overlay(alignment: .trailing) {
                if vm.isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
    }
}

#Preview {
    let vm = HabitDetailViewModel(habit: nil)
    return HabitDetailView(vm: vm)
}
