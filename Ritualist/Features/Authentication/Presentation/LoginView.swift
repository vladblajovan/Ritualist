import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @State private var showingDebugAccounts = false
    
    init(userSession: any UserSessionProtocol) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(userSession: userSession))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // App Logo/Header
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Welcome to Ritualist")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your habits, build your future")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.signIn()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                }
                
                Spacer()
                
                // Debug Section (only in debug builds)
                #if DEBUG
                VStack(spacing: 8) {
                    Button("Show Test Accounts") {
                        showingDebugAccounts = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text("All accounts use password: test123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                #endif
            }
            .padding(.horizontal, 32)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingDebugAccounts) {
            DebugAccountsView(viewModel: viewModel)
        }
    }
}

// MARK: - Debug Accounts View

#if DEBUG
struct DebugAccountsView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(MockAuthenticationService.testAccounts, id: \.email) { account in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(account.email)
                                .font(.headline)
                            Spacer()
                            Text(account.plan.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(planColor(account.plan))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Text("Password: \(account.password)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Use This Account") {
                            viewModel.email = account.email
                            viewModel.password = account.password
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Test Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func planColor(_ plan: SubscriptionPlan) -> Color {
        switch plan {
        case .free: return .gray
        case .monthly: return .blue
        case .annual: return .green
        }
    }
}
#endif

// MARK: - Login View Model

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userSession: any UserSessionProtocol
    
    init(userSession: any UserSessionProtocol) {
        self.userSession = userSession
    }
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    func signIn() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await userSession.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    let userSession = NoOpUserSession()
    return LoginView(userSession: userSession)
}