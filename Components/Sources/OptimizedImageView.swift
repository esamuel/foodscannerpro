import SwiftUI

public struct OptimizedImageView: View {
    // MARK: - Properties
    
    private let url: URL?
    private let contentMode: ContentMode
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadingError = false
    
    // MARK: - Initialization
    
    public init(url: URL?, contentMode: ContentMode = .fit) {
        self.url = url
        self.contentMode = contentMode
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fit ? .fit : .fill)
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if loadingError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadImage() async {
        guard let url = url else {
            loadingError = true
            return
        }
        
        isLoading = true
        loadingError = false
        
        do {
            image = try await ImageLoadingManager.shared.loadImage(from: url)
        } catch {
            loadingError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview

struct OptimizedImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            OptimizedImageView(url: URL(string: "https://example.com/image.jpg"))
                .frame(width: 200, height: 200)
            
            OptimizedImageView(url: nil)
                .frame(width: 200, height: 200)
        }
    }
} 