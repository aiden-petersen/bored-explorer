//
//  ThumbnailCache.swift
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

public class TokenThumbnailCache {
    private let cachedTokens = NSCache<NSNumber, UIImage>()
    private var loadingResponses = [Int: Task<UIImage, Error>]()
    private let cachedImageSize = CGSize(width: 256, height: 256)
    
    func token(id: NSNumber) -> UIImage? {
        return cachedTokens.object(forKey: id)
    }
                                    
    func fetchThumbnail(tokenMetadata: TokenMetadata) async throws -> UIImage {
        print("fetching token ID: \(tokenMetadata.id)")
        var thumbnailUrl: String? = tokenMetadata.thumbnailUrl
        if (thumbnailUrl == nil){ // means there was no thumbnail url in the metadata from alchemy
            thumbnailUrl = (try await getNft(tokenId: tokenMetadata.id)).imageUrl
        }
        
        guard let url = thumbnailUrl, let imageUrl = URL(string: url) else { throw TokenCacheError.ImageUrlError}
        
        let (data, response) = try await URLSession.shared.data(from: imageUrl)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw TokenCacheError.ImageRequestFailed }
        
        guard let image = UIImage(data: data) else {
            throw TokenCacheError.ImageDataError
        }
        // The thumbnail images from alchemy are 256x256, if the image we receive is bigger than that, then down size to that
        let thumbnailSizedImage = image.size.width > cachedImageSize.width ? resizeImage(image, cachedImageSize) : image
        
        // Crop image to get rid of rounded edges
        let cropRect = CGRect(
            x: 3,
            y: 3,
            width: thumbnailSizedImage.size.width - 2 * 3,
            height: thumbnailSizedImage.size.height - 2 * 3
        ).integral

        // Center crop the image
        let sourceCGImage = thumbnailSizedImage.cgImage!
        let croppedCGImage = sourceCGImage.cropping(
            to: cropRect
        )!
        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: thumbnailSizedImage.imageRendererFormat.scale,
            orientation: thumbnailSizedImage.imageOrientation
        )
        
        self.cachedTokens.setObject(croppedImage, forKey: tokenMetadata.id as NSNumber, cost: data.count)
        return croppedImage
    }

    // Returns the cached token if available, otherwise asynchronously loads and caches it.
    final func load(tokenMetadata: TokenMetadata) async throws -> UIImage {
        // Check for a cached token.
        if let cachedToken = token(id: tokenMetadata.id as NSNumber) {
            return cachedToken
        }
        
        // Check if image has already been requested and wait for that instead
        if let existingFetchTask = loadingResponses[tokenMetadata.id] {
            return try await existingFetchTask.value
        }
        // how to cancel a task
        // Go fetch the image.
        let fetchTask = Task {
            return try await fetchThumbnail(tokenMetadata: tokenMetadata)
        }
        loadingResponses[tokenMetadata.id] = fetchTask
        
        return try await fetchTask.value
    }
    
    // Populates cache
    final func prefetch(tokenMetadata: TokenMetadata) -> Void {
        // Check for a cached token.
        if token(id: tokenMetadata.id as NSNumber) != nil {
            return
        }
        
        // Check if token has already been requested and wait for that instead
        if loadingResponses[tokenMetadata.id] != nil {
            return
        }

        // Go fetch the token.
        loadingResponses[tokenMetadata.id] = Task {
            try await fetchThumbnail(tokenMetadata: tokenMetadata)
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
