import SwiftUI
import RitualistCore

public struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: HabitDetailViewModel
    let onDelete: (() -> Void)?

    public init(vm: HabitDetailViewModel, onDelete: (() -> Void)? = nil) {
        self.vm = vm
        self.onDelete = onDelete
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
                    HabitFormView(vm: vm, onDelete: onDelete)
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
                        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                        Task { @MainActor in
                            await saveHabit()
                        }
                    } label: {
                        Text(Strings.Button.save)
                    }
                    .disabled(vm.isSaving || !vm.isFormValid)
                }
            }
        }
        .presentationDragIndicator(.visible)
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
