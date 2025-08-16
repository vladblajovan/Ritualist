import SwiftUI
import FactoryKit
import RitualistCore

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

#Preview {
    let vm = HabitDetailViewModel(habit: nil)
    return HabitDetailView(vm: vm)
}
