import SwiftUI
import Foundation

/// An actor that manages image loading and caching operations
public actor ImageLoadingManager {
    // MARK: - Properties
    
    /// Shared instance for the image loading manager
    public static let shared = ImageLoadingManager()
    
    /// In-memory cache for loaded images
    private var imageCache: [String: CachedImage] = [:]
    
    /// Maximum cache size in bytes (default: 100MB)
    private let maxCacheSize: Int = 100 * 1024 * 1024
    
    /// Current cache size in bytes
    private var currentCacheSize: Int = 0
    
    // MARK: - Types
    
    private struct CachedImage {
        let image: UIImage
        let size: Int
        var lastAccessed: Date
    }
    
    // MARK: - Public Methods
    
    /// Loads an image from a URL with caching
    /// - Parameter url: The URL of the image to load
    /// - Returns: A UIImage if successful, nil otherwise
    public func loadImage(from url: URL) async throws -> UIImage {
        if let cachedImage = imageCache[url.absoluteString] {
            // Update last accessed time
            imageCache[url.absoluteString]?.lastAccessed = Date()
            return cachedImage.image
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageLoadingError.invalidImageData
        }
        
        // Estimate size in bytes (width * height * 4 bytes per pixel)
        let estimatedSize = Int(image.size.width * image.size.height * 4)
        
        let cachedImage = CachedImage(image: image, size: estimatedSize, lastAccessed: Date())
        imageCache[url.absoluteString] = cachedImage
        
        updateCacheSize()
        
        return image
    }
    
    /// Preloads a collection of images
    /// - Parameter urls: Array of image URLs to preload
    public func preloadImages(_ urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    try? await self.loadImage(from: url)
                }
            }
        }
    }
    
    /// Clears the entire image cache
    public func clearCache() {
        imageCache.removeAll()
        currentCacheSize = 0
    }
    
    // MARK: - Private Methods
    
    private func updateCacheSize() {
        let totalSize = imageCache.values.reduce(0) { $0 + $1.size }
        
        if totalSize > maxCacheSize {
            // Sort by last accessed date, oldest first
            let sortedCache = imageCache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
            
            var currentSize = totalSize
            var itemsToRemove: [String] = []
            
            for (key, value) in sortedCache {
                if currentSize <= maxCacheSize {
                    break
                }
                currentSize -= value.size
                itemsToRemove.append(key)
            }
            
            itemsToRemove.forEach { imageCache.removeValue(forKey: $0) }
        }
    }
}

// MARK: - Errors

public enum ImageLoadingError: Error {
    case invalidImageData
    case networkError
}

// MARK: - SwiftUI View Extension

public extension View {
    /// Loads and displays an image asynchronously with caching
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - placeholder: A view to show while loading
    /// - Returns: A view that will display the image when loaded
    func asyncImage<Placeholder: View>(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure(_):
                placeholder()
            @unknown default:
                placeholder()
            }
        }
    }
} 