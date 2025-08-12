import SwiftUI
import RitualistCore

public struct ConfirmationDialog: View {
    public let title: String
    public let message: String
    public let confirmTitle: String
    public let cancelTitle: String
    public let isDestructive: Bool
    public let onConfirm: () async -> Void
    public let onCancel: () -> Void
    
    public init(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        isDestructive: Bool = false,
        onConfirm: @escaping () async -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: Spacing.large) {
            VStack(spacing: Spacing.medium) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: Spacing.medium) {
                Button {
                    Task {
                        await onConfirm()
                    }
                } label: {
                    Text(confirmTitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isDestructive ? Color.red : Color(.systemGray5),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    onCancel()
                } label: {
                    Text(cancelTitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Spacing.large)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(Spacing.large)
    }
}

public extension View {
    func confirmationDialog<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented.wrappedValue = false
                    }
                
                content()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented.wrappedValue)
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    
    return Color(.systemGray6)
        .confirmationDialog(isPresented: $isPresented) {
            ConfirmationDialog(
                title: "Delete Habit",
                message: "Are you sure you want to delete this habit? This action cannot be undone.",
                confirmTitle: "Delete",
                cancelTitle: "Cancel",
                isDestructive: true,
                onConfirm: {
                    print("Confirmed")
                    isPresented = false
                },
                onCancel: {
                    print("Cancelled")
                    isPresented = false
                }
            )
        }
}
