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
    private let cachedImages = NSCache<NSNumber, UIImage>()
    private var loadingResponses = [Int: Task<UIImage, Error>]()
    private var imageSize: CGSize
    
    init(imageSize: CGSize){
        self.imageSize = imageSize
    }
    
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
        let resizedImage = resizeImage(image, imageSize);
        self.cachedImages.setObject(resizedImage, forKey: tokenId as NSNumber, cost: data.count)
        return resizedImage
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


func resizeImage(_ image: UIImage, _ targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}
