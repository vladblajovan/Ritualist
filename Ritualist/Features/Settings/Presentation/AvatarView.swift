import SwiftUI
import PhotosUI
import FactoryKit
import RitualistCore

public struct AvatarView: View {
    public let name: String
    public let imageData: Data?
    public let size: CGFloat
    public let showEditBadge: Bool
    public let onEditTapped: () -> Void
    
    public init(
        name: String,
        imageData: Data? = nil,
        size: CGFloat = 80,
        showEditBadge: Bool = true,
        onEditTapped: @escaping () -> Void = {}
    ) {
        self.name = name
        self.imageData = imageData
        self.size = size
        self.showEditBadge = showEditBadge
        self.onEditTapped = onEditTapped
    }
    
    public var body: some View {
        ZStack {
            Button {
                onEditTapped()
            } label: {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: size, height: size)
                    
                    // Content (initials or image)
                    if let imageData = imageData,
                       let uiImage = UIImage(data: imageData) {
                        // Show user image
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else if !initials.isEmpty {
                        // Show initials
                        Text(initials)
                            .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!showEditBadge)
            
            // Edit badge
            if showEditBadge {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            onEditTapped()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AppColors.brand)
                                    .frame(width: size * 0.3, height: size * 0.3)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: size * 0.15, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    private var backgroundColor: Color {
        if imageData != nil {
            return Color.clear
        } else if !initials.isEmpty {
            return initialsBackgroundColor
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var initials: String {
        let words = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count >= 2 {
            // First letter of first name + first letter of last name
            let first = String(words[0].prefix(1)).uppercased()
            let last = String(words[1].prefix(1)).uppercased()
            return first + last
        } else if words.count == 1 {
            // First two letters of single name
            let word = words[0]
            if word.count >= 2 {
                return String(word.prefix(2)).uppercased()
            } else {
                return String(word.prefix(1)).uppercased()
            }
        }
        
        return ""
    }
    
    private var initialsBackgroundColor: Color {
        // Generate a consistent color based on the name
        let hash = name.hashValue
        let colors: [Color] = [
            AppColors.brand,
            .blue,
            .green,
            .orange,
            .purple,
            .red,
            .pink,
            .indigo
        ]
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

public struct AvatarImagePicker: View {
    @Binding public var selectedImageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false

    public let name: String
    public let currentImageData: Data?
    public let onImageSelected: (Data?) -> Void
    public let onDismiss: () -> Void

    public init(
        name: String,
        currentImageData: Data?,
        selectedImageData: Binding<Data?>,
        onImageSelected: @escaping (Data?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.name = name
        self.currentImageData = currentImageData
        self._selectedImageData = selectedImageData
        self.onImageSelected = onImageSelected
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                Text("Profile Photo")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Current avatar preview
                AvatarView(
                    name: name,
                    imageData: selectedImageData ?? currentImageData,
                    size: 120,
                    showEditBadge: false
                )
                
                VStack(spacing: Spacing.medium) {
                    // Photo picker button
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Choose from Photos")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.brand, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                        .font(.body.weight(.medium))
                    }
                    .disabled(isLoading)
                    
                    // Remove photo button (only show if there's an image)
                    if selectedImageData != nil || currentImageData != nil {
                        Button {
                            selectedImageData = nil
                            onImageSelected(nil)
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(.red)
                            .font(.body.weight(.medium))
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, Spacing.large)
                
                if isLoading {
                    ProgressView("Processing image...")
                        .padding()
                }
                
                Spacer()
            }
            .padding(Spacing.large)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let imageData = selectedImageData {
                            onImageSelected(imageData)
                        }
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading)
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadImageData(from: newItem)
            }
        }
    }
    
    @MainActor
    private func loadImageData(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Resize image if needed
                if let resizedData = resizeImageData(data, maxSize: 512) {
                    selectedImageData = resizedData
                } else {
                    selectedImageData = data
                }
            }
        } catch {
            Container.shared.debugLogger().log("Failed to load avatar image: \(error)", level: .error, category: .ui)
        }
        
        isLoading = false
    }
    
    private func resizeImageData(_ data: Data, maxSize: CGFloat) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        
        let currentSize = uiImage.size
        let maxDimension = max(currentSize.width, currentSize.height)
        
        // Only resize if the image is larger than maxSize
        guard maxDimension > maxSize else { return data }
        
        let scale = maxSize / maxDimension
        let newSize = CGSize(
            width: currentSize.width * scale,
            height: currentSize.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.8)
    }
}

#Preview("Empty Avatar") {
    AvatarView(name: "", imageData: nil, size: 80) {}
}

#Preview("Initials Avatar - Single Name") {
    AvatarView(name: "John", imageData: nil, size: 80) {}
}

#Preview("Initials Avatar - Full Name") {
    AvatarView(name: "John Doe", imageData: nil, size: 80) {}
}

#Preview("Avatar Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AvatarView(name: "Small", size: 40) {}
            AvatarView(name: "Medium", size: 60) {}
            AvatarView(name: "Large", size: 80) {}
            AvatarView(name: "XL", size: 100) {}
        }
        
        AvatarView(name: "No Badge", size: 80, showEditBadge: false) {}
    }
    .padding()
}
