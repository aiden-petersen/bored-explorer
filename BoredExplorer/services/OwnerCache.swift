//
//  OnwerCache.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 23/06/22.
//

import UIKit
import Foundation

public class TokenOwnerCache {
    private let cachedOwners = NSCache<NSNumber, NSString>()
    private var loadingResponses = [Int: Task<String, Error>]()
    
    func owner(id: NSNumber) -> String? {
        return cachedOwners.object(forKey: id) as String?
    }
                                    
    func fetchOwner(tokenId: Int) async throws -> String {
        print("fetching owner for token ID: \(tokenId)")
        
        let owner = try await getOwner(tokenId: tokenId)
        
        self.cachedOwners.setObject(owner as NSString, forKey: tokenId as NSNumber, cost: 1)
        return owner
    }

    // Returns the cached token owner if available, otherwise asynchronously loads and caches it.
    final func load(tokenId: Int) async throws -> String {
        // Check for a cached item
        if let cachedOwner = owner(id: tokenId as NSNumber) {
            return cachedOwner
        }
        
        // Check if owner has already been requested and wait for that instead
        if let existingFetchTask = loadingResponses[tokenId] {
            return try await existingFetchTask.value
        }
        // Go fetch the owner
        let fetchTask = Task {
            return try await fetchOwner(tokenId: tokenId)
        }
        loadingResponses[tokenId] = fetchTask
        
        return try await fetchTask.value
    }
    
    // Populates cache
    final func prefetch(tokenId: Int) -> Void {
        // Check for a cached owner.
        if owner(id: tokenId as NSNumber) != nil {
            return
        }
        
        // Check if token owner has already been requested and wait for that instead
        if loadingResponses[tokenId] != nil {
            return
        }

        // Go fetch the token owner.
        loadingResponses[tokenId] = Task {
            try await fetchOwner(tokenId: tokenId)
        }
    }
}

