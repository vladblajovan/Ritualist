import SwiftUI

public struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: () async -> Void
    
    public init(
        title: String,
        message: String,
        retryAction: @escaping () async -> Void
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            ActionButton.primary(title: "Retry") {
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await retryAction()
                }
            }
        }
    }
}

#Preview {
    ErrorView(
        title: "Failed to Load",
        message: "Unable to connect to the server"
    ) {
        // Mock retry action
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}