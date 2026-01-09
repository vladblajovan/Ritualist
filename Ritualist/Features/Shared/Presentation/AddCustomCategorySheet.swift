import SwiftUI
import RitualistCore

public struct AddCustomCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName: String = ""
    @State private var selectedEmoji: String = "📝"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    let onSave: (String, String) async -> Bool  // Returns success
    
    // Common emojis for categories
    private let emojiOptions = [
        "📝", "💪", "🧘", "⚡", "📚", "👥", "🎯", "🏃", "🍎", "💰",
        "🎨", "🏠", "🚗", "📱", "💼", "🎵", "🌱", "❤️", "⭐", "🔥"
    ]
    
    public init(onSave: @escaping (String, String) async -> Bool) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                // Header explanation
                VStack(spacing: Spacing.medium) {
                    Text("🏷️")
                        .font(.system(size: 60))

                    VStack(spacing: Spacing.small) {
                        Text(Strings.CategoryManagement.createTitle)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(Strings.CategoryManagement.createSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, Spacing.large)
                
                VStack(spacing: Spacing.large) {
                    // Category name input
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(Strings.CategoryManagement.nameLabel)
                            .font(.headline)
                            .fontWeight(.semibold)

                        TextField(Strings.CategoryManagement.namePlaceholder, text: $categoryName)
                            .textFieldStyle(.plain)
                            .autocapitalization(.words)
                            .disableAutocorrection(false)
                    }

                    // Emoji selection
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(Strings.CategoryManagement.chooseEmoji)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.medium) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedEmoji == emoji ? AppColors.brand.opacity(0.2) : Color.clear,
                                            in: Circle()
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedEmoji == emoji ? AppColors.brand : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Spacing.large)
                
                Spacer()
            }
            .navigationTitle(Strings.CategoryManagement.newCategory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Button.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Button.save) {
                        saveCategory()
                    }
                    .disabled(isFormInvalid || isLoading)
                    .fontWeight(.semibold)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView(Strings.CategoryManagement.creatingCategory)
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    private var isFormInvalid: Bool {
        categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveCategory() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            let success = await onSave(trimmedName, selectedEmoji)
            
            isLoading = false
            
            if success {
                dismiss()
            } else {
                errorMessage = Strings.CategoryManagement.failedToCreate
            }
        }
    }
}
