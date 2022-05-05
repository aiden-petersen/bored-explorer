//
//  ImageCache.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 1/05/22.
//

import UIKit
import Foundation

enum TokenCacheError: Error {
    case ImageUrlError
    case ImageRequestFailed
    case ImageDataError
}

public class TokenCache {
    public static let publicCache = TokenCache()
    private let cachedImages = NSCache<NSNumber, UIImage>()
    private var loadingResponses = [Int: Task<UIImage, Error>]()
    
    public final func image(id: NSNumber) -> UIImage? {
        return cachedImages.object(forKey: id)
    }
                                    
    func fetchNftImage(tokenId: Int) async throws -> UIImage {
        print("fetching: \(tokenId)")
        let imageUrl = (try await getNft(tokenId: tokenId)).imageUrl
        
        guard let url  = URL(string: imageUrl) else { throw TokenCacheError.ImageUrlError}
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw TokenCacheError.ImageRequestFailed }
        
        guard let image = UIImage(data: data) else {
            throw TokenCacheError.ImageDataError
        }
        self.cachedImages.setObject(image, forKey: tokenId as NSNumber, cost: data.count)
        return image
    }

    // Returns the cached image if available, otherwise asynchronously loads and caches it.
    final func load(tokenId: Int) async throws -> UIImage {
        // Check for a cached image.
        if let cachedImage = image(id: tokenId as NSNumber) {
            return cachedImage
        }
        
        // Check if image has already been requested and wait for that instead
        if let existingFetchTask = loadingResponses[tokenId] {
            return try await existingFetchTask.value
        }
        // how to cancel a task
        // Go fetch the image.
        let fetchTask = Task {
            return try await fetchNftImage(tokenId: tokenId)
        }
        loadingResponses[tokenId] = fetchTask
        
        
        let image = try await fetchTask.value
        loadingResponses.removeValue(forKey: tokenId)
        return image
    }
    
    // Populates cache
    final func prefetch(tokenId: Int) -> Void {
        // Check for a cached image.
        if image(id: tokenId as NSNumber) != nil {
            return
        }
        
        // Check if image has already been requested and wait for that instead
        if loadingResponses[tokenId] != nil {
            return
        }

        // Go fetch the image.
        loadingResponses[tokenId] = Task {
            try await fetchNftImage(tokenId: tokenId)
        }
        
        Task {
            try await loadingResponses[tokenId]?.value
            loadingResponses.removeValue(forKey: tokenId)
        }
    }
}
